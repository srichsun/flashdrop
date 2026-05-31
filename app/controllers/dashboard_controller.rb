# Landing page after login. Just shows the current store for now;
# real dashboard content comes with later features.
class DashboardController < ApplicationController
  def show
    @tenant = current_user.tenant
  end
end
