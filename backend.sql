-- Run once in the restaurant owner's Supabase SQL editor.
create table public.cafe_admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.cafe_admins enable row level security;
create function public.is_cafe_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.cafe_admins where user_id = auth.uid());
$$;
revoke all on function public.is_cafe_admin() from public;
grant execute on function public.is_cafe_admin() to authenticated;
create table public.cafe_menu (
 id text primary key, category text not null check(length(category) between 1 and 60),
 name text not null check(length(name) between 1 and 120), price integer not null check(price between 0 and 100000),
 image text not null default '', illustrative boolean not null default false,
 available boolean not null default true, active boolean not null default true,
 sort_order integer not null default 0, updated_at timestamptz not null default now()
);
create table public.cafe_settings (
 id boolean primary key default true check(id), name text not null default '99 Cafe',
 whatsapp text not null default '8801735603989', phone text not null default '01724041186',
 address text not null default '152 East Kafrul, Near Uttar Kafrul School Gate, Kachukhet, Dhaka 1206',
 accepting_orders boolean not null default true, delivery_fee integer not null default 0 check(delivery_fee between 0 and 10000),
 notice text not null default 'Orders are subject to restaurant confirmation.'
);
insert into public.cafe_settings(id) values(true);
create table public.cafe_orders (
 id uuid primary key, created_at timestamptz not null default now(), customer_name text not null,
 phone text not null, method text not null check(method in ('delivery','pickup')),
 address text not null, notes text not null, items jsonb not null,
 subtotal integer not null, delivery_fee integer not null, total integer not null,
 status text not null default 'new' check(status in ('new','accepted','preparing','ready','completed','cancelled'))
);
create index cafe_orders_created on public.cafe_orders(created_at desc);
create index cafe_orders_phone on public.cafe_orders(phone,created_at desc);
alter table public.cafe_menu enable row level security;
alter table public.cafe_settings enable row level security;
alter table public.cafe_orders enable row level security;
grant select on public.cafe_menu,public.cafe_settings to anon,authenticated;
grant insert,update,delete on public.cafe_menu to authenticated;
grant update on public.cafe_settings to authenticated;
grant select,update on public.cafe_orders to authenticated;
create policy menu_read on public.cafe_menu for select to anon,authenticated using(true);
create policy menu_manage on public.cafe_menu for all to authenticated using(public.is_cafe_admin()) with check(public.is_cafe_admin());
create policy settings_read on public.cafe_settings for select to anon,authenticated using(true);
create policy settings_manage on public.cafe_settings for update to authenticated using(public.is_cafe_admin()) with check(public.is_cafe_admin());
create policy orders_read on public.cafe_orders for select to authenticated using(public.is_cafe_admin());
create policy orders_update on public.cafe_orders for update to authenticated using(public.is_cafe_admin()) with check(public.is_cafe_admin());

-- No anonymous access to order rows. This function validates and prices requests on the server.
create function public.place_cafe_order(request_id uuid, customer jsonb, lines jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare cfg public.cafe_settings; product public.cafe_menu; line jsonb; snapshot jsonb='[]';
 amount integer=0; quantity integer; fee integer; mobile text; result public.cafe_orders;
begin
 if request_id is null then raise exception 'Missing request ID'; end if;
 perform pg_advisory_xact_lock(990019);
 select * into result from public.cafe_orders where id=request_id;
 if found then return jsonb_build_object('id',result.id,'total',result.total,'duplicate',true); end if;
 select * into cfg from public.cafe_settings where id=true;
 if not cfg.accepting_orders then raise exception 'The restaurant is not accepting orders right now'; end if;
 mobile:=regexp_replace(coalesce(customer->>'phone',''),'[^0-9]','','g');
 if left(mobile,2)='88' then mobile:=substr(mobile,3); end if;
 if mobile !~ '^01[3-9][0-9]{8}$' then raise exception 'Enter a valid Bangladesh mobile number'; end if;
 if length(trim(coalesce(customer->>'name',''))) not between 1 and 80 then raise exception 'Name is required (80 characters maximum)'; end if;
 if coalesce(customer->>'method','') not in ('delivery','pickup') then raise exception 'Invalid order type'; end if;
 if length(coalesce(customer->>'address',''))>400 or length(coalesce(customer->>'notes',''))>400 then raise exception 'Address or notes too long'; end if;
 if customer->>'method'='delivery' and length(trim(coalesce(customer->>'address','')))<5 then raise exception 'Delivery address is required'; end if;
 if jsonb_typeof(lines) is distinct from 'array' then raise exception 'Invalid cart'; end if;
 if jsonb_array_length(lines) not between 1 and 52 then raise exception 'Cart must contain between 1 and 52 items'; end if;
 if (select count(*) from jsonb_array_elements(lines))<>(select count(distinct value->>'id') from jsonb_array_elements(lines)) then raise exception 'Duplicate cart items'; end if;
 if (select count(*) from public.cafe_orders where phone=mobile and created_at>now()-interval '10 minutes')>=3 then raise exception 'Too many recent requests. Please call the restaurant'; end if;
 if (select count(*) from public.cafe_orders where created_at>now()-interval '1 minute')>=60 then raise exception 'Ordering is busy. Please try again shortly'; end if;
 for line in select value from jsonb_array_elements(lines) loop
   if coalesce(line->>'quantity','') !~ '^[0-9]{1,2}$' then raise exception 'Invalid quantity'; end if;
   quantity:=(line->>'quantity')::integer;
   if quantity not between 1 and 99 then raise exception 'Invalid quantity'; end if;
   select * into product from public.cafe_menu where id=line->>'id' and active and available;
   if not found then raise exception 'An item is no longer available. Refresh your cart'; end if;
   if (line->>'price')::integer is distinct from product.price then raise exception 'A price has changed. Refresh and review your cart'; end if;
   amount:=amount+product.price*quantity;
   snapshot:=snapshot||jsonb_build_array(jsonb_build_object('id',product.id,'name',product.name,'category',product.category,'price',product.price,'quantity',quantity));
 end loop;
 fee:=case when customer->>'method'='delivery' then cfg.delivery_fee else 0 end;
 insert into public.cafe_orders(id,customer_name,phone,method,address,notes,items,subtotal,delivery_fee,total)
 values(request_id,trim(customer->>'name'),mobile,customer->>'method',coalesce(customer->>'address',''),coalesce(customer->>'notes',''),snapshot,amount,fee,amount+fee);
 return jsonb_build_object('id',request_id,'total',amount+fee,'duplicate',false);
end; $$;
revoke all on function public.place_cafe_order(uuid,jsonb,jsonb) from public;
grant execute on function public.place_cafe_order(uuid,jsonb,jsonb) to anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('cafe-photos','cafe-photos',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy cafe_photo_insert on storage.objects for insert to authenticated with check(bucket_id='cafe-photos' and public.is_cafe_admin());
create policy cafe_photo_update on storage.objects for update to authenticated using(bucket_id='cafe-photos' and public.is_cafe_admin()) with check(bucket_id='cafe-photos' and public.is_cafe_admin());
create policy cafe_photo_delete on storage.objects for delete to authenticated using(bucket_id='cafe-photos' and public.is_cafe_admin());
alter publication supabase_realtime add table public.cafe_menu,public.cafe_settings,public.cafe_orders;
-- Create an email/password user in Supabase Authentication, then grant owner access:
-- insert into public.cafe_admins(user_id) select id from auth.users where email='OWNER_EMAIL';
-- Do not expose service-role keys or grant anonymous access to orders.
