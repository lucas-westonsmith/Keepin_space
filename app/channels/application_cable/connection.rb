module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      Rails.logger.info "🔑 Utilisateur authentifié via WebSocket : #{current_user.email} (ID: #{current_user.id})"
    end

    private

    def find_verified_user
      user_id = cookies.signed[:user_id]
      if user_id && (verified_user = User.find_by(id: user_id))
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
