-- Grants the 'admin' role to antoine.jasnault@gmail.com, in addition to
-- the 'operator' role already assigned by handle_new_user() at signup.
-- has_role() checks for the existence of a role row, so this doesn't
-- remove 'operator' — it just adds 'admin' alongside it.

begin;

insert into public.user_roles (user_id, role)
select id, 'admin'
from public.profiles
where email = 'antoine.jasnault@gmail.com'
on conflict (user_id, role) do nothing;

select p.email, ur.role
from public.profiles p
join public.user_roles ur on ur.user_id = p.id
where p.email = 'antoine.jasnault@gmail.com';

commit;
