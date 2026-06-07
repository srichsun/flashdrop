require "digest"

# A revocable, single-use refresh token. Only the SHA-256 digest is stored, so a
# DB leak can't be replayed to mint access tokens. Rotated on every use (see
# Api::V1::SessionsController#refresh), with reuse-detection.
class RefreshToken < ApplicationRecord
  belongs_to :user

  LIFETIME = 30.days

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw.to_s)
  end

  # Returns [record, raw_token]. The raw token is only ever visible here — the
  # caller hands it to the client; we keep just the digest.
  def self.issue(user, user_agent: nil)
    raw = SecureRandom.urlsafe_base64(48)
    record = create!(user: user, token_digest: digest(raw),
                     expires_at: LIFETIME.from_now, user_agent: user_agent)
    [ record, raw ]
  end

  def self.find_by_raw(raw)
    raw.present? ? find_by(token_digest: digest(raw)) : nil
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end
end
