class Post < ApplicationRecord
  has_rich_text :body

  before_validation :generate_slug, on: :create

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :published, -> { where.not(published_at: nil).where(published_at: ..Time.current) }
  scope :recent_first, -> { order(published_at: :desc) }

  def to_param
    slug
  end

  def published?
    published_at.present? && published_at <= Time.current
  end

  private
    def generate_slug
      return if title.blank?

      base = title.parameterize
      candidate = base
      suffix = 1
      while Post.where(slug: candidate).where.not(id: id).exists?
        suffix += 1
        candidate = "#{base}-#{suffix}"
      end
      self.slug = candidate
    end
end
