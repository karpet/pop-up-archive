require 'feedjira'

Feedjira::Feed.add_feed_class(Feedjira::Parser::MediaRSSFeedBurner)
Feedjira::Feed.add_feed_class(Feedjira::Parser::MediaRSS)

Feedjira::Feed.add_common_feed_entry_element("link", :value => :href, :as => :enclosure_url, :with => {:rel => "enclosure"})
Feedjira::Feed.add_common_feed_entry_element("link", :value => :length, :as => :enclosure_length, :with => {:rel => "enclosure"})
Feedjira::Feed.add_common_feed_entry_element("link", :value => :type, :as => :enclosure_type, :with => {:rel => "enclosure"})

Feedjira::Feed.add_common_feed_entry_element("enclosure", :value => :length, :as => :enclosure_length)
Feedjira::Feed.add_common_feed_entry_element("enclosure", :value => :type, :as => :enclosure_type)
Feedjira::Feed.add_common_feed_entry_element("enclosure", :value => :url, :as => :enclosure_url)
