module HideFromBullet
  def skip_bullet
    if defined?(Bullet)
      previous_value = Bullet.enable?
      Bullet.enable = false
    end
    yield
  ensure
    Bullet.enable = previous_value if defined?(Bullet)
  end
end
