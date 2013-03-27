module Renderable
  extend ActiveSupport::Concern
  include AutoHtml

  included do
    before_save :render_content, if: Proc.new{|model| model.content.present?}
  end

  private

  def render_content
    @user_ids = Array.new
    require 'redcarpet'
    renderer = Redcarpet::Render::HTML.new filter_html: true, no_images: true, safe_links_only: true, with_toc_data: true
    extensions = {space_after_headers: true, no_intra_emphasis: true, tables: true, fenced_code_blocks: true, autolink: false, strikethrough: true, superscript: true}
    hashtagged = self.content.gsub(/(^|\s)@([[:alnum:]_-]+)/u) { |tag|
      if user = User.where(name: $2).first
        @user_ids << user.id
        "#{$1}[@#{$2}](#{Rails.application.routes.url_helpers.user_path(user)})"
      else
        tag
      end
    }.gsub(/(^|\s)#([[:alnum:]_-]+)/u) { |tag|
      "#{$1}[##{$2}](#{Rails.application.routes.url_helpers.messages_path(q: $2)})"
    }
    redcarpet = Redcarpet::Markdown.new(renderer, extensions)
    self.rendered_content = redcarpet.render(hashtagged)
    self.rendered_content = auto_html(self.rendered_content) {
      image
      youtube
      dailymotion
      flickr
      gist
      google_map
      google_video
      soundcloud
      twitter
      vimeo
      link rel: 'nofollow', target: '_blank'
    }
  end
end
