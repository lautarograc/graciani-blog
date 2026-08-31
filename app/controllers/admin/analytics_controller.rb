module Admin
  class AnalyticsController < BaseController
    PERIODS = { "7" => 7, "30" => 30, "90" => 90, "365" => 365, "all" => nil }.freeze

    SEARCH_DOMAINS = /google|bing\.|duckduckgo|search\.yahoo|baidu|yandex|ecosia/i
    SOCIAL_DOMAINS = /twitter\.|x\.com|t\.co|facebook|instagram|linkedin|reddit|news\.ycombinator|lobste\.rs|threads\.net|bsky\.app|mastodon/i

    def show
      @period = PERIODS.key?(params[:period]) ? params[:period] : "30"
      since = PERIODS[@period]&.days&.ago

      visits = Ahoy::Visit.all
      visits = visits.where(started_at: since..) if since

      @total_visits = visits.count
      @unique_visitors = visits.distinct.count(:visitor_token)

      @visits_per_day = daily_series(visits.group("date(started_at)").count, since)
      @countries = visits.where.not(country: nil).group(:country, :country_code).count
                          .sort_by { |_, count| -count }.first(10)
      @sources = source_breakdown(visits)
      @top_referrers = visits.where.not(referring_domain: [ nil, "" ]).group(:referring_domain).count
                              .sort_by { |_, count| -count }.first(10)

      events = Ahoy::Event.where(name: "Page engagement").joins(:visit)
      events = events.where(ahoy_visits: { started_at: since.. }) if since

      @engagement = engagement_summary(events)
      @top_posts = post_engagement(events)
    end

    private
      def daily_series(counts_by_date, since)
        counts_by_date = counts_by_date.transform_keys { |date| date.is_a?(String) ? Date.parse(date) : date }
        start_date = since ? since.to_date : (counts_by_date.keys.min || Date.current)
        (start_date..Date.current).map { |date| [ date, counts_by_date[date] || 0 ] }
      end

      def source_breakdown(visits)
        counts = Hash.new(0)
        visits.pluck(:referring_domain).each { |domain| counts[categorize_domain(domain)] += 1 }
        counts.sort_by { |_, count| -count }
      end

      def categorize_domain(domain)
        return "Direct" if domain.blank?
        return "Search" if domain.match?(SEARCH_DOMAINS)
        return "Social" if domain.match?(SOCIAL_DOMAINS)
        "Referral"
      end

      def engagement_summary(events)
        seconds = []
        scroll_percents = []

        events.find_each do |event|
          props = event.properties || {}
          seconds << props["seconds_engaged"].to_i if props["seconds_engaged"]
          scroll_percents << props["max_scroll_percent"].to_f if props.key?("max_scroll_percent")
        end

        {
          avg_seconds: average(seconds),
          median_seconds: median(seconds),
          avg_scroll_percent: average(scroll_percents)
        }
      end

      def post_engagement(events)
        grouped = Hash.new { |h, k| h[k] = { title: nil, count: 0, seconds: [], scroll_percents: [] } }

        events.find_each do |event|
          props = event.properties || {}
          post_id = props["post_id"]
          next unless post_id

          entry = grouped[post_id]
          entry[:title] ||= props["post_title"]
          entry[:count] += 1
          entry[:seconds] << props["seconds_engaged"].to_i if props["seconds_engaged"]
          entry[:scroll_percents] << props["max_scroll_percent"].to_f if props.key?("max_scroll_percent")
        end

        grouped.map do |post_id, data|
          {
            post_id: post_id,
            title: data[:title],
            count: data[:count],
            avg_seconds: average(data[:seconds]),
            avg_scroll_percent: average(data[:scroll_percents])
          }
        end.sort_by { |row| -row[:count] }
      end

      def average(values)
        return 0 if values.empty?
        (values.sum / values.size.to_f).round
      end

      def median(values)
        return 0 if values.empty?
        sorted = values.sort
        mid = sorted.size / 2
        sorted.size.odd? ? sorted[mid] : ((sorted[mid - 1] + sorted[mid]) / 2.0).round
      end
  end
end
