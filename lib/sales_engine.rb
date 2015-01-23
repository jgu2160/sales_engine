require 'csv'
require_relative 'merchant_repository'
require_relative 'invoice_repository'
require_relative 'item_repository'
require_relative 'invoice_item_repository'
require_relative 'customer_repository'
require_relative 'transaction_repository'
require_relative 'generic_repo'
require_relative 'sales_finder'
require 'byebug'

class SalesEngine
  include SalesFinder
	attr_reader :merchant_repository, :invoice_repository, :item_repository, :invoice_repository, :invoice_item_repository, :customer_repository, :transaction_repository

  def initialize(file_path)
    @file_path = file_path
  end

	def startup
		@merchant_repository  = MerchantRepository.new("#{@file_path}merchants.csv", Merchant, self)
		@invoice_repository = InvoiceRepository.new("#{@file_path}invoices.csv", Invoice, self)
		@item_repository = ItemRepository.new("#{@file_path}items.csv", Item, self)
		@invoice_item_repository = InvoiceItemRepository.new("#{@file_path}invoice_items.csv", InvoiceItem, self)
		@customer_repository = CustomerRepository.new("#{@file_path}customers.csv", Customer, self)
		@transaction_repository = TransactionRepository.new("#{@file_path}transactions.csv", Transaction, self)
	end

  def analyze_success_fail_of_customer_by_invoice(invoice_per_customer_per_merchant)
    invoice_per_customer_per_merchant.each do |cust_id, invoices|
      invoices.each_with_index do |invoice, index| 
        transactions = self.find_transactions_by_invoice_id(invoice.info[:id])
        results = transactions.map {|transaction| transaction.info[:result]}
        results.any? {|result| result == "success"} ? invoices[index] = 1 : invoices[index] = -1
      end
    end
    invoice_per_customer_per_merchant
  end

  def show_success_fail_of_customer_by_invoice_per_merchant(merch_id)
    invoices_grouped_by_customer = self.group_invoices_by_customer_per_merchant(merch_id)
    self.analyze_success_fail_of_customer_by_invoice(invoices_grouped_by_customer)
  end

  def find_customers_with_pending_invoices(merch_id)
    invoices_in_success_fail_per_customer = self.show_success_fail_of_customer_by_invoice_per_merchant(merch_id)
   customers_with_pending_invoices_hash = invoices_in_success_fail_per_customer.select {|cust_id, successes| successes.include?(-1)}
   customers_with_pending_invoices_hash.map {|customer, fails| customer}
  end
  
  def find_favorite_customer(merch_id)
    invoices_in_success_fail_per_customer = self.show_success_fail_of_customer_by_invoice_per_merchant(merch_id)
    min, max = invoices_in_success_fail_per_customer.minmax_by {|cust_id, successes| successes.inject(:+)}
    max[0]
  end

  def group_invoices_by_customer_per_merchant(merch_id)
    invoices = self.find_invoices_by_merch_id(merch_id)
    invoices.group_by.each_with_index {|invoice, index| invoices[index].info[:customer_id]}
  end

  def divide_customers_by_success_fail
    #success_fail = partition {|transaction| transaction.result == "success"}
  end
end
