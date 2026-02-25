-- Allow users to delete their own notifications
-- Required for swipe-to-dismiss and Clear All functionality in the notification center

CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  USING (auth.uid() = user_id);
