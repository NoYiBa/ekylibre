# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: outgoing_deliveries
#
#  address_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode             :string(255)      not null
#  net_mass         :decimal(19, 4)
#  number           :string(255)      not null
#  recipient_id     :integer          not null
#  reference_number :string(255)
#  sale_id          :integer
#  sent_at          :datetime
#  transport_id     :integer
#  transporter_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#  with_transport   :boolean          not null
#


require 'test_helper'

class OutgoingDeliveryTest < ActiveSupport::TestCase
  test_fixtures

  test "ship giving a transporter" do
    OutgoingDelivery.ship(OutgoingDelivery.all, transporter_id: entities(:entities_001).id)
  end

  test "ship without transporter" do
    assert_raise StandardError do
      OutgoingDelivery.ship(OutgoingDelivery.all)
    end
  end

  test "prevent empty items" do
    item = outgoing_delivery_items(:outgoing_delivery_items_001).attributes.slice("product_id", "population", "shape")
    delivery = OutgoingDelivery.new items_attributes: {"123456789"=>{"product_id"=>"", "_destroy"=>"false"}, "852" => item}
    delivery.items.map(&:net_mass)
  end

end
