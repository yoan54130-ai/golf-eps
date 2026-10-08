-- Golf EPS : sécurisation de la base (à exécuter une fois dans Supabase > SQL Editor)
--
-- Résultat :
--   * tout le monde (élèves) peut LIRE les classes et AJOUTER une partie ;
--   * seul le compte enseignant peut LIRE / SUPPRIMER l'historique et gérer les classes.
--
-- 1) Remplacez VOTRE_EMAIL_ENSEIGNANT ci-dessous par l'e-mail du compte enseignant
--    (créé dans Supabase > Authentication > Users > Add user, avec « Auto Confirm User »).
-- 2) Désactivez les inscriptions : Authentication > Sign In / Providers > Email
--    > désactiver « Allow new users to sign up ».

create or replace function public.est_enseignant()
returns boolean
language sql stable
as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) = lower('VOTRE_EMAIL_ENSEIGNANT') $$;

alter table golf_classes enable row level security;
alter table golf_history enable row level security;

-- anciennes règles ouvertes à tous
drop policy if exists "acces public classes" on golf_classes;
drop policy if exists "acces public historique" on golf_history;
drop policy if exists "classes lecture" on golf_classes;
drop policy if exists "classes ecriture enseignant" on golf_classes;
drop policy if exists "historique ajout" on golf_history;
drop policy if exists "historique lecture enseignant" on golf_history;
drop policy if exists "historique suppression enseignant" on golf_history;

-- classes : lecture pour tous, modification réservée à l'enseignant
create policy "classes lecture" on golf_classes
  for select to anon, authenticated using (true);
create policy "classes ecriture enseignant" on golf_classes
  for all to authenticated using (public.est_enseignant()) with check (public.est_enseignant());

-- historique : ajout pour tous, lecture et suppression réservées à l'enseignant
create policy "historique ajout" on golf_history
  for insert to anon, authenticated with check (true);
create policy "historique lecture enseignant" on golf_history
  for select to authenticated using (public.est_enseignant());
create policy "historique suppression enseignant" on golf_history
  for delete to authenticated using (public.est_enseignant());
