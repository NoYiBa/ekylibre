Exchanges.add_importer :telepac_land_parcels do |file, w|

  # Unzip file
  dir = w.tmp_dir
  Zip::File.open(file) do |zile|
    zile.each do |entry|
      entry.extract(dir.join(entry.name))
    end
  end


  #############################################################################
  # Import landparcel_shapefile from TELEPAC
  # -- field_name
  # PACAGE
  # NUMERO_SI (land_parcel number)
  # NUMERO (land_parcel_cluster number id)
  # CAMPAGNE (campaign)
  # DPT_NUM (department zone number)
  # SURF_TOT (land_parcel_cluster area)
  # COMMUNE
  # TYPE (cf http://www.maine-et-loire.gouv.fr/IMG/pdf/Dossier-PAC-2013_notice_cultures-varietes.pdf)
  # CODE_VAR
  # SURF_DECL (land_parcel area)
  # TYPE_PARC
  # AGRI_BIO
  # ANNEE_ENGM



  RGeo::Shapefile::Reader.open(dir.join("parcelle.shp").to_s, srid: 2154) do |file|
    # Set number of shapes
    w.count = file.size

    # Find good variant
    land_parcel_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
    cultivable_zone_variant = ProductNatureVariant.import_from_nomenclature(:cultivable_zone)

    file.each do |record|
      attributes = {
        initial_born_at: Time.utc(1, 1, 1, 0, 0, 0),
        variant_id: land_parcel_variant.id,
        name: LandParcel.model_name.human + " " + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
        work_number: :land_parcel_abbreviation.tl(default: "LP") + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
        variety: "land_parcel",
        initial_owner: Entity.of_company,
        identification_number: :land_parcel_abbreviation.tl(default: "LP") + record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s + record.attributes['NUMERO_SI'].to_s
      }

      # Find or create land parcel
      # TODO: Use a find_by_shape_similarity to determine existence of the land parcel
      unless land_parcel = LandParcel.find_by(attributes.slice(:work_number, :variety, :identification_number))
        land_parcel = LandParcel.create!(attributes)
      end

      geom = Charta::Geometry.new(record.geometry).transform(:WGS84) if record.geometry

      # if geometry ,load into georeadings
      if geom and geom.area.to_d(:square_meter) > 10.0
        land_parcel.read!(:shape, geom, at: land_parcel.initial_born_at)

        a = (land_parcel.shape_area.to_d / land_parcel_variant.net_surface_area.to_d(:square_meter))

        # TODO Fix population zero?
        #puts a.inspect.blue

        land_parcel.read!(:population, a, at: land_parcel.initial_born_at)

        #puts land_parcel.population.inspect.red

        geo_attributes = {
          name: land_parcel.name,
          number: land_parcel.work_number,
          nature: :polygon
        }
        unless georeading = Georeading.find_by(geo_attributes.slice(:number))
          georeading = Georeading.new(geo_attributes)
        end
        georeading.content = land_parcel.shape
        georeading.save!
      end



      # link a land parcel to a land parcel cluster
      if land_parcel_cluster = LandParcelCluster.find_by(work_number: record.attributes['NUMERO'].to_s)
        land_parcel_cluster.add(land_parcel)
      end


      # Create activities if option true
      if Preference.get!(:create_activities_from_telepac, true, :boolean).value
        cultivable_zone = nil
        if geom and geom.area.to_d(:square_meter) > 10.0
          # Create a cultivable zone
          attributes = {
            variant_id: cultivable_zone_variant.id,
            name: CultivableZone.model_name.human + " " + land_parcel.name,
            work_number: :cultivable_zone_abbreviation.tl(default: "CZ") + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
            variety: "cultivable_zone",
            initial_born_at: land_parcel.born_at,
            initial_owner: Entity.of_company,
            identification_number: :cultivable_zone_abbreviation.tl(default: "CZ") + record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s + record.attributes['NUMERO_SI'].to_s
          }
          unless cultivable_zone = CultivableZone.find_by(attributes.slice(:work_number, :variety, :identification_number))
            cultivable_zone = CultivableZone.create!(attributes)
          end


          # Add readings
          cultivable_zone.read!(:shape, geom, at: cultivable_zone.born_at)
          cultivable_zone.read!(:population, (cultivable_zone.shape_area.to_d / cultivable_zone_variant.net_surface_area.to_d(:square_meter)), at: cultivable_zone.born_at)

          # Link cultivable zone and land parcel
          attributes = {
            group_id: cultivable_zone.id,
            member_id: land_parcel.id,
            shape: geom,
            population: land_parcel.population
          }
          unless CultivableZoneMembership.find_by(attributes.slice(:group, :member))
            CultivableZoneMembership.create!(attributes)
          end

        end


        # Create a campaign if not exist
        attributes = {
          harvest_year: record.attributes['CAMPAGNE'].to_i,
          closed: false
        }
        unless campaign = Campaign.find_by(attributes.slice(:harvest_year))
          campaign = Campaign.create!(attributes)
        end

        # Create an activity if not exist with production_code
        item = Nomen::ProductionNatures.find_by(telepac_crop_code: record.attributes['TYPE'].to_s)
        unless item and activity_family = Nomen::ActivityFamilies[item.activity]
          raise "No activity family found. (#{record.attributes['TYPE']})"
        end

        attributes = {
          nature: :main,
          family: activity_family.name,
          name: activity_family.human_name
        }
        unless activity = Activity.find_by(attributes.slice(:family, :nature))
          activity = Activity.create!(attributes)
        end


        # Create a production if not exist
        if product_nature_variant = ProductNatureVariant.import_from_nomenclature(item.variant_support.to_s)
          attributes = {
            campaign_id: campaign.id,
            activity_id: activity.id,
            variant_id: product_nature_variant.id,
            state: :validated
          }
          unless production = Production.find_by(attributes.slice(:campaign_id, :activity, :variant_id))
            production = Production.create!(attributes)
          end
          if cultivable_zone
            # if exist, this production has static_support
            production.static_support = true
            production.state = :validated
            production.save!
            # and create a support for this production
            production.supports.create!(storage_id: cultivable_zone.id, started_at: Date.new(campaign.harvest_year - 1, 10, 1), stopped_at: Date.new(campaign.harvest_year, 8, 1))
          end

        end

      end

      w.check_point
    end
  end


end
