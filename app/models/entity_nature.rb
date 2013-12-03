# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Mérigon
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
# == Table: entity_natures
#
#  abbreviation :string(255)      not null
#  active       :boolean          default(TRUE), not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             
#  id           :integer          not null, primary key
#  in_name      :boolean          default(TRUE), not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  physical     :boolean          not null
#  title        :string(255)      
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

class EntityNature < ActiveRecord::Base
  belongs_to :company
  has_many :entities, :foreign_key=>:nature_id 


  def before_validation
    self.in_name = false if self.physical
    if self.physical
      self.title = self.abbreviation if self.title.blank?
    else
      self.title = ''
    end
  end



end
