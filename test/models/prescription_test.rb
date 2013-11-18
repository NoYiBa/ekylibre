# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: prescriptions
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  delivered_on     :date
#  description      :text
#  document_id      :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  prescriptor_id   :integer          not null
#  reference_number :string(255)
#  updated_at       :datetime         not null
#  updater_id       :integer
#
require 'test_helper'

class PrescriptionTest < ActiveSupport::TestCase

  test "presence of fixtures" do
    # assert_equal 2, Prescription.count
  end

end