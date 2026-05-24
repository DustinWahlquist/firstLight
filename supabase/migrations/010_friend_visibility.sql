-- Allow reading bird_cards for public profiles or accepted friends
create policy "Friends and public profiles can view bird cards"
  on bird_cards for select
  using (
    exists (
      select 1 from profiles
      where id = bird_cards.user_id and is_public = true
    )
    or exists (
      select 1 from friendships
      where status = 'accepted'
        and (
          (requester_id = auth.uid() and addressee_id = bird_cards.user_id)
          or (addressee_id = auth.uid() and requester_id = bird_cards.user_id)
        )
    )
  );
