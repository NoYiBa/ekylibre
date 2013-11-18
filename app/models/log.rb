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
# == Table: logs
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  description   :text
#  event         :string(255)      not null
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  observed_at   :datetime         not null
#  origin_id     :integer
#  origin_object :text
#  origin_type   :string(255)
#  owner_id      :integer          not null
#  owner_object  :text
#  owner_type    :string(255)      not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#


class Log < ActiveRecord::Base
  belongs_to :origin, :polymorphic => true
  belongs_to :owner, :polymorphic => true

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]
end