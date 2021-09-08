YNAB_TOKEN = ENV['YNAB_TOKEN']
YNAB_BUDGET_ID = ENV['YNAB_BUDGET_ID']

def get_accounts
  if File.exist?('tmp/accounts.yaml')
    accounts = YAML.load(File.read('tmp/accounts.yaml'))
    puts 'accounts imported from disk'
  else
    ynab_api = YNAB::API.new(YNAB_TOKEN)

    accounts_response = ynab_api.accounts.get_accounts(YNAB_BUDGET_ID)
    all_accounts = accounts_response.data.accounts
    open_accounts = all_accounts.select { |account| account.closed == false }
    direct_import_linked = open_accounts.select { |account| account.direct_import_linked == false }
    accounts = direct_import_linked

    File.open('tmp/accounts.yaml', 'w') { |f| f.write(YAML.dump(accounts)) }
  end

  accounts
end

def get_transactions
  if File.exist?('tmp/transactions.yaml')
    transactions = YAML.load(File.read('tmp/transactions.yaml'))
    puts 'transactions imported from disk'
  else
    ynab_api = YNAB::API.new(YNAB_TOKEN)

    transactions_response = ynab_api.transactions.get_transactions(YNAB_BUDGET_ID)
    transactions = transactions_response.data.transactions

    File.open('tmp/transactions.yaml', 'w') { |f| f.write(YAML.dump(transactions)) }
  end

  transactions
end

def get_budget_months
  if File.exist?('tmp/months.yaml')
    months = YAML.load(File.read('tmp/months.yaml'))
    puts 'months imported from disk'
  else
    ynab_api = YNAB::API.new(YNAB_TOKEN)

    months_response = ynab_api.months.get_budget_months(YNAB_BUDGET_ID)
    months = months_response.data.months

    File.open('tmp/months.yaml', 'w') { |f| f.write(YAML.dump(months)) }
  end

  months
end

def process_transactions_by_account
  months = get_budget_months
  transactions = get_transactions
  accounts = get_accounts

  @data = Hash.new

  accounts.each do |account|
    account_transactions = transactions.select {|transaction| transaction.account_id == account.id }
    @data[account.name] = []

    months.each do |month|
      count = 0

      account_transactions.each do |transaction|
        if transaction.date < month.month
          count += transaction.amount
        end
      end

      if count != 0
        @data[account.name] << {
          :month => month.to_s,
          :balance => count
        }
      end
    end
  end

  @data.to_json
end

def process_transactions_by_month
  months = import_months
  transactions = import_transactions
  accounts = import_accounts

  @data = Hash.new

  months.each do |m|
    month = m.to_s
    @data[month] = []

    accounts.each do |account|
      account_transactions = transactions.select {|transaction| transaction.account_id == account.id }

      count = 0
      account_transactions.each do |transaction|
        if transaction.date < m
          count += transaction.amount
        end
      end

      if count > 0
        @data[month] << {
          :id => account.id,
          :name => account.name,
          :balance => count
        }
      end
    end
  end
end
