-- Incident photos for CampusSupport. Run once in the Supabase SQL Editor; it is
-- safe to run again. Photos are stored under incidents/{uid}/{fileName}.
--
-- Users sign in with Firebase, so these checks read the signed Firebase ID
-- token. Firebase tokens carry no Supabase role claim, so requests arrive as
-- the anon role and the policies must cover it. A request with no token has no
-- email or issuer and is refused. firestore.rules holds the same two domains.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('incident-photos', 'incident-photos', true, 5242880, array['image/*'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.firebase_email_domain()
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when auth.jwt() ->> 'iss' = 'https://securetoken.google.com/studentsupport-88445'
      and auth.jwt() ->> 'aud' = 'studentsupport-88445'
    then lower(split_part(auth.jwt() ->> 'email', '@', 2))
  end
$$;

drop policy if exists "Members can read incident photos" on storage.objects;
drop policy if exists "Members can upload to their own folder" on storage.objects;
drop policy if exists "Owners and staff can delete incident photos" on storage.objects;

-- The bucket is public, so photo links open without this. Supabase needs it to
-- find a file before deleting it.
create policy "Members can read incident photos"
on storage.objects for select
to anon, authenticated
using (
  bucket_id = 'incident-photos'
  and public.firebase_email_domain() in ('alustudent.com', 'alueducation.com')
);

create policy "Members can upload to their own folder"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id = 'incident-photos'
  and public.firebase_email_domain() in ('alustudent.com', 'alueducation.com')
  and (storage.foldername(name))[1] = 'incidents'
  and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
);

-- Lets the app clean up after a failed submission, and lets staff remove photos
-- when they delete a report.
create policy "Owners and staff can delete incident photos"
on storage.objects for delete
to anon, authenticated
using (
  bucket_id = 'incident-photos'
  and (
    public.firebase_email_domain() = 'alueducation.com'
    or (
      public.firebase_email_domain() = 'alustudent.com'
      and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
    )
  )
);
