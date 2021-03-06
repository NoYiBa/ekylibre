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
# == Table: gap_items
#
#  amount        :decimal(19, 4)   default(0.0), not null
#  created_at    :datetime         not null
#  creator_id    :integer
#  currency      :string(3)        not null
#  gap_id        :integer          not null
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  pretax_amount :decimal(19, 4)   default(0.0), not null
#  tax_id        :integer
#  updated_at    :datetime         not null
#  updater_id    :integer
#
class GapItem < Ekylibre::Record::Base
  belongs_to :gap, inverse_of: :items
  belongs_to :tax
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_presence_of :amount, :currency, :gap, :pretax_amount
  #]VALIDATORS]
  # validates_numericality_of :amount, :pretax_amount, greater_than_or_equal_to: 0

  sums :gap, :items, :pretax_amount, :amount

  def taxes_amount
    self.amount - self.pretax_amount
  end

end
