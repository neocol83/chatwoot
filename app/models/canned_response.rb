# == Schema Information
#
# Table name: canned_responses
#
#  id         :integer          not null, primary key
#  content    :text
#  short_code :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#
class CannedResponse < ApplicationRecord
  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  belongs_to :account
  has_one_attached :canned_file

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])

    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"

    order(Arel.sql(order_clause) => :desc)
  }

  # Método para obtener la URL del archivo adjunto
  def file_path
    return unless canned_file.attached? && canned_file.persisted?

    Rails.application.routes.url_helpers.rails_blob_url(canned_file, only_path: true)
  end

  # Método para actualizar el archivo adjunto
  def update_canned_file(new_file)
    return unless new_file.present?

    canned_file.purge_later if canned_file.attached? # Eliminar archivo anterior si existe
    canned_file.attach(new_file) # Adjuntar nuevo archivo
  end
end
