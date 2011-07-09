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

class SubscriptionNaturesController < ApplicationController
  manage_restfully :nature=>"SubscriptionNature.natures.first[1]"

  list(:conditions=>{:company_id=>['@current_company.id']}, :children=>:products) do |t|
    t.column :name, :url=>{:id=>'nil', :action=>:index, :controller=>:subscriptions, :nature_id=>"RECORD.id"}
    t.column :nature_label, :children=>false
    t.column :actual_number, :children=>false
    t.column :reduction_rate, :children=>false
    t.action :increment, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :decrement, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  # Displays the main page with the list of subscription natures
  def index
  end

  def decrement
    return unless @subscription_nature = find_and_check(:subscription_nature)
    @subscription_nature.decrement!(:actual_number)
    notify_success(:new_actual_number, :actual_number=>@subscription_nature.actual_number)
    redirect_to_back
  end

  def increment
    return unless @subscription_nature = find_and_check(:subscription_nature)
    @subscription_nature.increment!(:actual_number)
    notify_success(:new_actual_number, :actual_number=>@subscription_nature.actual_number)
    redirect_to_back
  end

end
