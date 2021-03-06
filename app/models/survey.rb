class Survey < ApplicationRecord
  include Likable

  belongs_to :user
  belongs_to :project
  has_many :feedbacks, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :options, dependent: :destroy

  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  validate :has_options
  validates :duration, numericality: { greater_than: 0 }

  mount_uploader :cover_image, ImageUploader
  mount_uploader :social_card, ImageUploader

  scope :recent, -> { order('id DESC') }

  def fetch_feedback_of someone
    feedbacks.find_by(user: someone)
  end

  def feedbacked?(someone)
    feedbacks.exists? user: someone
  end

  def open?
    return true if duration.days <= 0
    (self.created_at + duration.days).future?
  end

  def percentage(option)
    max_count = options.map{|o| o.all_feedbacks_count}.max
    return 0 if max_count == 0

    (option.all_feedbacks_count / max_count.to_f * 100).ceil
  end

  def feedback_users_count
    feedbacks.count('distinct user_id')
  end

  def has_anonymous_feedbacks?
    options.sum(:anonymous_feedbacks_count) > 0
  end

  private

  def has_options
    errors.add(:options, 'must add at least one options') if self.options.blank?
  end
end

