class ActivitySpendingBreakdown
  RECENT_QUARTERS = 7
  OLDER_QUARTERS = 13
  UPCOMING_QUARTERS = 5

  Actuals = Struct.new(:spend, :refund) {
    def net
      spend - refund
    end
  }

  def initialize(activity: nil, report:)
    @activity = activity
    @activity_presenter = ActivityPresenter.new(activity)
    @report = report
  end

  def headers
    identifiers.keys +
      metadata.keys +
      old_quarters_net_spending_headers +
      recent_quarters_detailed_spending_headers +
      upcoming_quarters_forecasts_headers
  end

  def values
    combined_hash.values
  end

  def combined_hash
    identifiers
      .merge(metadata)
      .map { |key, value| [key, value.call] }.to_h
      .merge(old_quarters_net_spending)
      .merge(recent_quarters_detailed_spending)
      .merge(upcoming_quarters_forecasts)
  end

  private

  def identifiers
    {
      "RODA identifier" => -> { @activity.roda_identifier },
      "BEIS identifier" => -> { @activity.beis_id },
      "Delivery partner identifier" => -> { @activity.delivery_partner_identifier },
    }
  end

  def metadata
    {
      "Title" => -> { @activity_presenter.display_title },
      "Description" => -> { @activity_presenter.description },
      "Programme status" => -> { @activity_presenter.programme_status },
      "ODA eligibility" => -> { @activity_presenter.oda_eligibility },
    }
  end

  def old_quarters_net_spending_headers
    previous_quarters.take(OLDER_QUARTERS).map do |quarter|
      "#{quarter} actual net"
    end
  end

  def old_quarters_net_spending
    previous_quarters_actuals.take(OLDER_QUARTERS).map { |quarter, actual|
      ["#{quarter} actual net", format_amount(actual.net)]
    }.to_h
  end

  def recent_quarters_detailed_spending_headers
    previous_quarters.drop(OLDER_QUARTERS).flat_map do |quarter|
      [
        "#{quarter} actual spend",
        "#{quarter} actual refund",
        "#{quarter} actual net",
      ]
    end
  end

  def recent_quarters_detailed_spending
    previous_quarters_actuals.drop(OLDER_QUARTERS).flat_map { |quarter, actual|
      [
        ["#{quarter} actual spend", format_amount(actual.spend)],
        ["#{quarter} actual refund", format_amount(actual.refund)],
        ["#{quarter} actual net", format_amount(actual.net)],
      ]
    }.to_h
  end

  def upcoming_quarters_forecasts_headers
    upcoming_quarters.map do |quarter|
      "#{quarter} forecast"
    end
  end

  def upcoming_quarters_forecasts
    forecasts = PlannedDisbursementOverview.new(@activity).snapshot(@report).all_quarters

    upcoming_quarters.map { |quarter|
      ["#{quarter} forecast", format_amount(forecasts.value_for(**quarter))]
    }.to_h
  end

  def format_amount(value)
    "%.2f" % value
  end

  def previous_quarters_actuals
    @_previous_quarters_actuals ||= begin
      transactions = ActivityTransactions.new(@activity, @report)

      previous_quarters.map do |quarter|
        key = [quarter.financial_year.start_year, quarter.quarter]
        [quarter, transactions.index[key]]
      end
    end
  end

  def previous_quarters
    count = RECENT_QUARTERS + OLDER_QUARTERS
    financial_quarter.preceding(count - 1) + [financial_quarter]
  end

  def upcoming_quarters
    financial_quarter.following(UPCOMING_QUARTERS)
  end

  def financial_quarter
    @_financial_quarter ||= @report.own_financial_quarter
  end

  class ActivityTransactions
    attr_reader :index

    def initialize(activity, report)
      @activity = activity
      @report = report
      @index = Hash.new { |hash, key| hash[key] = Actuals.new(0, 0) }

      load_transaction_data
    end

    private

    def load_transaction_data
      report_activity_transactions.each do |txn|
        key = [txn.financial_year, txn.financial_quarter]

        if txn.value < 0
          @index[key].refund += txn.value.abs
        else
          @index[key].spend += txn.value
        end
      end
    end

    def report_activity_transactions
      Transaction
        .joins(:report)
        .where(parent_activity_id: @activity.id)
        .merge(Report.historically_up_to(@report))
    end
  end
end
