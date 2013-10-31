# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class FinancialYearsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on DESC") do |t|
    t.column :code, :url=>true
    t.column :closed
    t.column :started_on, :url=>true
    t.column :stopped_on, :url=>true
    t.column :currency
    t.column :currency_precision
    # t.action :close, :if => '!RECORD.closed and RECORD.closable?'
    t.action :edit, :if => '!RECORD.closed'  
    t.action :destroy, :if => '!RECORD.closed'  
  end

  # Displays the main page with the list of financial years
  def index
  end

  list(:account_balances, :joins=>:account, :conditions=>{:company_id=>['@current_company.id'], :financial_year_id=>['session[:current_financial_year_id]']}, :order=>"number") do |t|
    t.column :number, :through=>:account, :url=>true
    t.column :name, :through=>:account, :url=>true
    t.column :local_debit, :currency => "RECORD.financial_year.currency"
    t.column :local_credit, :currency => "RECORD.financial_year.currency"
  end

  list(:asset_depreciations, :conditions=>{:company_id=>['@current_company.id'], :financial_year_id=>['session[:current_financial_year_id]']}) do |t|
    t.column :name, :through=>:asset, :url=>true
    t.column :started_on
    t.column :stopped_on
    t.column :amount, :currency => true
  end

  # Displays details of one financial year selected with +params[:id]+
  def show
    return unless @financial_year = find_and_check(:financial_year)
    respond_to do |format|
      format.html do 
        session[:current_financial_year_id] = @financial_year.id
        if @financial_year.closed? and @financial_year.account_balances.size.zero?
          @financial_year.compute_balances!
        end
        t3e @financial_year.attributes
      end
      format.pdf do 
        if params[:n] == "balance_sheet" 
          render_print_balance_sheet(@financial_year)
        else
          render_print_income_statement(@financial_year)
        end
      end
    end
  end

  def compute_balances
    return unless @financial_year = find_and_check(:financial_year)
    @financial_year.compute_balances!
    redirect_to_current    
  end


  def close
    # Launch close process
    return unless @financial_year = find_and_check(:financial_year)
    if request.post?
      params[:journal_id] = @current_company.journals.create!(:nature=>"renew").id if params[:journal_id]=="0"
      if @financial_year.close(params[:financial_year][:stopped_on].to_date, :renew_id=>params[:journal_id])
        notify_success(:closed_financial_years)
        redirect_to(:action=>:index)
      end
    else
      journal = @current_company.journals.find(:first, :conditions => {:nature => "forward"})
      params[:journal_id] = (journal ? journal.id : 0)
    end
    t3e @financial_year.attributes
  end

  def new
    @financial_year = @current_company.financial_years.new
    f = @current_company.financial_years.find(:first, :order=>"stopped_on DESC")
    @financial_year.started_on = f.stopped_on+1.day unless f.nil?
    @financial_year.started_on ||= Date.today
    @financial_year.stopped_on = (@financial_year.started_on+1.year-1.day).end_of_month
    @financial_year.code = @financial_year.default_code    
    @financial_year.currency = @financial_year.previous.currency if @financial_year.previous
    @financial_year.currency ||= @current_company.default_currency
    render_restfully_form
  end

  def create
    @financial_year = FinancialYear.new(params[:financial_year])
    @financial_year.company_id = @current_company.id
    return if save_and_redirect(@financial_year)
    render_restfully_form
  end

  def edit
    return unless @financial_year = find_and_check(:financial_years)
    t3e @financial_year.attributes
    render_restfully_form
  end

  def update
    return unless @financial_year = find_and_check(:financial_years)
    @financial_year.attributes = params[:financial_year]
    return if save_and_redirect(@financial_year)
    t3e @financial_year.attributes
    render_restfully_form
  end

  def destroy
    return unless @financial_year = find_and_check(:financial_years)
    @financial_year.destroy if @financial_year.destroyable?
    redirect_to :action => :index
  end

  def generate_last_journal_entry
    return unless @financial_year = find_and_check(:financial_year)
    if request.get?
      params[:assets_depreciations] ||= 1
    elsif request.post?
      @financial_year.generate_last_journal_entry(params)
      redirect_to journal_entry_url(@financial_year.last_journal_entry)
    end
    t3e @financial_year.attributes    
  end

end