class Domain < ActiveRecord::Base
  include Renderable

  has_many :users, dependent: :destroy
  has_many :forums, dependent: :destroy
  has_many :topics, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :small_messages, dependent: :destroy

  validates_format_of :theme, :with => /^#[0-9a-fA-F]{6}$/
  validates_format_of :url, :with => URI::regexp(%w(http https)), :allow_blank => true

  has_attached_file :banner
  attr_accessible :banner, :content, :css, :description, :keywords, :theme, :title, :url
end
