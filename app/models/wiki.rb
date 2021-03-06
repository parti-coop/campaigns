class Wiki < ApplicationRecord
  include Likable

  belongs_to :user
  belongs_to :project
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :wiki_revisions, dependent: :destroy

  scope :recent, -> { order('updated_at DESC') }

  attr_accessor :revision_note

  def fallback_social_image_url
    if self.project.try(:read_attribute, :social_image).present?
      self.project.social_image_url
    end
  end
end
