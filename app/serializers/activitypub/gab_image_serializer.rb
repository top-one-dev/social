# frozen_string_literal: true

class ActivityPub::GabImageSerializer < ActivityPub::ImageSerializer
  def url
    object
      .sub('gab://avatar/', 'https://goji.live/media/user/')
      .sub('gab://header/', 'https://goji.live/media/user/')
  end

  def media_type; end
end
