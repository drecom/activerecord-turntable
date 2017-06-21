class UserWithCallbacks < User
  self.table_name = "users"

  after_destroy :on_destroy
  after_save    :on_update

  def on_destroy
  end

  def on_update
  end
end
