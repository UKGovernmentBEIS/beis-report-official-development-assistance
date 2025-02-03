class User < ApplicationRecord
  devise :two_factor_authenticatable, :rememberable, :secure_validatable, :recoverable,
    otp_secret_encryption_key: ENV["SECRET_KEY_BASE"]

  belongs_to :organisation
  has_and_belongs_to_many :additional_organisations, class_name: "Organisation", join_table: "organisations_users"
  has_many :historical_events
  validates_presence_of :name, :email
  validates :email, with: :email_cannot_be_changed_after_create, on: :update
  validates :organisation_id, exclusion: {in: ->(user) { user.additional_organisations.map(&:id) }}

  before_save :ensure_otp_secret!, if: -> { otp_required_for_login && otp_secret.nil? }

  FORM_FIELD_TRANSLATIONS = {
    organisation_id: :organisation
  }.freeze

  scope :active, -> { where(deactivated_at: nil, anonymised_at: nil) }
  scope :deactivated, -> { where(anonymised_at: nil).where.not(deactivated_at: nil) }

  scope :all_active, -> {
    active.includes(:organisation).joins(:organisation).order("organisations.name ASC, users.name ASC")
  }
  scope :all_deactivated, -> {
    deactivated.includes(:organisation).joins(:organisation).order("users.deactivated_at ASC, organisations.name ASC, users.name ASC")
  }

  delegate :service_owner?, :partner_organisation?, to: :organisation

  def active
    deactivated_at.blank?
  end
  alias_method :active?, :active

  def organisation
    if Current.user_organisation
      return Organisation.find(Current.user_organisation)
    end
    super
  end

  def primary_organisation
    Organisation.find_by_id(organisation_id)
  end

  def all_organisations
    Organisation.where(id: [organisation_id, additional_organisations.map(&:id)].flatten)
  end

  def additional_organisations?
    additional_organisations.any?
  end

  def current_organisation_id
    Current.user_organisation || organisation.id
  end

  def active_for_authentication?
    active
  end

  def confirmed_for_mfa?
    mobile_number.present? && mobile_number_confirmed_at.present?
  end

  private

  def ensure_otp_secret!
    self.otp_secret = User.generate_otp_secret
  end

  def email_cannot_be_changed_after_create
    return true if anonymised_at.present?

    if email.to_s.squish.downcase != email_was.to_s.squish.downcase
      errors.add(:email, :cannot_be_changed)
    end
  end

  # :nocov:
  ##
  # Decrypt and return the `encrypted_otp_secret` attribute which was used in
  # versions of devise-two-factor < 5.x. In practice this will be in use for the
  # gap between deployment of 5.x and the running of
  # db/data/20250117151047_regenerate_otp_secrets.rb, and will be removed in
  # the very next release. Lifted from
  # https://github.com/devise-two-factor/devise-two-factor/blob/main/UPGRADING.md
  # @return [String] The decrypted OTP secret
  def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    hmac_iterations = 2000 # a default set by the Encryptor gem
    key = self.class.otp_secret_encryption_key
    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag - we use
    # Galois Counter Mode which is an authenticated encryption mode
    cipher_text = raw_cipher_text[0..-17]
    auth_tag = raw_cipher_text[-16..-1] # standard:disable Style/SlicingWithRange

    # this algorithm lifted from
    # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

    # create an OpenSSL object which will decrypt the AES cipher with 256 bit
    # keys in Galois Counter Mode (GCM). See
    # https://ruby.github.io/openssl/OpenSSL/Cipher.html
    cipher = OpenSSL::Cipher.new("aes-256-gcm")

    # tell the cipher we want to decrypt. Symmetric algorithms use a very
    # similar process for encryption and decryption, hence the same object can
    # do both.
    cipher.decrypt

    # Use a Password-Based Key Derivation Function to generate the key actually
    # used for encryption from the key we got as input.
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

    # set the Initialization Vector (IV)
    cipher.iv = iv

    # The tag must be set after calling Cipher#decrypt, Cipher#key= and
    # Cipher#iv=, but before calling Cipher#final. After all decryption is
    # performed, the tag is verified automatically in the call to Cipher#final.
    #
    # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
    cipher.auth_tag = auth_tag

    # auth_data must be set after auth_tag has been set when decrypting See
    # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
    # we are not adding any authenticated data but OpenSSL docs say this should
    # still be called.
    cipher.auth_data = ""

    # #update is (somewhat confusingly named) the method which actually
    # performs the decryption on the given chunk of data. Our OTP secret is
    # short so we only need to call it once.
    #
    # It is very important that we call #final because:
    #
    # 1. The authentication tag is checked during the call to #final
    # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
    #    to call #final to get it to process the last chunk properly. The output
    #    of #final should be appended to the decrypted value. This isn't
    #    required for streaming cipher modes but including it is a best practice
    #    so that your code will continue to function correctly even if you later
    #    change to a block cipher mode.
    cipher.update(cipher_text) + cipher.final
  end
  # :nocov:
end
