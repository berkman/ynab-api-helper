require 'json'
require 'yaml'
require 'dotenv/load'
require 'pp'
require 'fileutils'
require 'ynab'
require 'bigdecimal'
require 'bigdecimal/util'
require 'date'
require_relative 'ynab-lib'

puts process_transactions_by_account
