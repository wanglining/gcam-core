# Before we can load headers we need some paths defined.  They
# may be provided by a system environment variable or just
# having already been set in the workspace
if( !exists( "ENERGYPROC_DIR" ) ){
    if( Sys.getenv( "ENERGYPROC" ) != "" ){
        ENERGYPROC_DIR <- Sys.getenv( "ENERGYPROC" )
    } else {
        stop("Could not determine location of energy data system. Please set the R var ENERGYPROC_DIR to the appropriate location")
    }
}

# Universal header file - provides logging, file support, etc.
source(paste(ENERGYPROC_DIR,"/../_common/headers/GCAM_header.R",sep=""))
source(paste(ENERGYPROC_DIR,"/../_common/headers/ENERGY_header.R",sep=""))
logstart( "L221.en_supply.R" )
adddep(paste(ENERGYPROC_DIR,"/../_common/headers/GCAM_header.R",sep=""))
adddep(paste(ENERGYPROC_DIR,"/../_common/headers/ENERGY_header.R",sep=""))
printlog( "Primary fuel handling sectors" )

# -----------------------------------------------------------------------------
# 1. Read files

sourcedata( "COMMON_ASSUMPTIONS", "A_common_data", extension = ".R" )
sourcedata( "COMMON_ASSUMPTIONS", "level2_data_names", extension = ".R" )
sourcedata( "MODELTIME_ASSUMPTIONS", "A_modeltime_data", extension = ".R" )
sourcedata( "ENERGY_ASSUMPTIONS", "A_energy_data", extension = ".R" )
GCAM_region_names <- readdata( "COMMON_MAPPINGS", "GCAM_region_names")
calibrated_techs <- readdata( "ENERGY_MAPPINGS", "calibrated_techs" )
A21.sector <- readdata( "ENERGY_ASSUMPTIONS", "A21.sector" )
A_regions <- readdata( "ENERGY_ASSUMPTIONS", "A_regions" )
A21.subsector_logit <- readdata( "ENERGY_ASSUMPTIONS", "A21.subsector_logit" )
A21.subsector_shrwt <- readdata( "ENERGY_ASSUMPTIONS", "A21.subsector_shrwt" )
A21.subsector_interp <- readdata( "ENERGY_ASSUMPTIONS", "A21.subsector_interp" )
A21.globaltech_coef <- readdata( "ENERGY_ASSUMPTIONS", "A21.globaltech_coef" )
A21.globaltech_cost <- readdata( "ENERGY_ASSUMPTIONS", "A21.globaltech_cost" )
A21.globaltech_shrwt <- readdata( "ENERGY_ASSUMPTIONS", "A21.globaltech_shrwt" )
A21.globaltech_keyword <- readdata( "ENERGY_ASSUMPTIONS", "A21.globaltech_keyword" )
A21.globaltech_secout <- readdata( "ENERGY_ASSUMPTIONS", "A21.globaltech_secout" )
A21.rsrc_info <- readdata( "ENERGY_ASSUMPTIONS", "A21.rsrc_info" )
A21.tradedtech_coef <- readdata( "ENERGY_ASSUMPTIONS", "A21.tradedtech_coef" )
A21.tradedtech_cost <- readdata( "ENERGY_ASSUMPTIONS", "A21.tradedtech_cost" )
A21.tradedtech_shrwt <- readdata( "ENERGY_ASSUMPTIONS", "A21.tradedtech_shrwt" )
A21.globaltech_secout <- readdata( "ENERGY_ASSUMPTIONS", "A21.globaltech_secout" )
L111.Prod_EJ_R_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L111.Prod_EJ_R_F_Yh" )
L121.in_EJ_R_TPES_unoil_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L121.in_EJ_R_TPES_unoil_Yh" )
L121.in_EJ_R_TPES_crude_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L121.in_EJ_R_TPES_crude_Yh" )
A_an_input_subsector <- readdata( "AGLU_ASSUMPTIONS", "A_an_input_subsector" )
L108.ag_Feed_Mt_R_C_Y <- readdata( "AGLU_LEVEL1_DATA", "L108.ag_Feed_Mt_R_C_Y" )
L132.ag_an_For_Prices <- readdata( "AGLU_LEVEL1_DATA", "L132.ag_an_For_Prices" )

# -----------------------------------------------------------------------------
# 2. Build tables for CSVs
# 2a. Supplysector information
printlog( "L221.Supplysector_en: Supply sector information for upstream energy handling sectors" )
L221.SectorLogitTables <- get_logit_fn_tables( A21.sector, names_SupplysectorLogitType, base.header="Supplysector_",
    include.equiv.table=T, write.all.regions=T, has.traded=T )
L221.Supplysector_en <- write_to_all_regions( A21.sector, names_Supplysector, has.traded=T )

printlog( "L221.SectorUseTrialMarket_en: Supplysector table that indicates to the model to create solved markets for them." )
# The traded markets tend to be a good canidate to solve explicitly since they tie together
# many solved markets.
L221.SectorUseTrialMarket_en <- write_to_all_regions( subset( A21.sector, traded == T ), c( reg, supp ), has.traded=T )
L221.SectorUseTrialMarket_en$use.trial.market <- 1

# 2b. Subsector information
printlog( "L221.SubsectorLogit_en: Subsector logit exponents of upstream energy handling sectors" )
L221.SubsectorLogitTables <- get_logit_fn_tables( A21.subsector_logit, names_SubsectorLogitType,
    base.header="SubsectorLogit_", include.equiv.table=F, write.all.regions=T, has.traded=T )
L221.SubsectorLogit_en <- write_to_all_regions( A21.subsector_logit, names_SubsectorLogit, has.traded=T )

printlog( "L221.SubsectorShrwt_en and L221.SubsectorShrwtFllt_en: Subsector shareweights of upstream energy handling sectors" )
if( any( !is.na( A21.subsector_shrwt$year ) ) ){
	L221.SubsectorShrwt_en <- write_to_all_regions( A21.subsector_shrwt[ !is.na( A21.subsector_shrwt$year ), ], names_SubsectorShrwt, has.traded=T )
	}
if( any( !is.na( A21.subsector_shrwt$year.fillout ) ) ){
	L221.SubsectorShrwtFllt_en <- write_to_all_regions( A21.subsector_shrwt[ !is.na( A21.subsector_shrwt$year.fillout ), ], names_SubsectorShrwtFllt, has.traded=T )
	}

printlog( "L221.SubsectorInterp_en and L221.SubsectorInterpTo_en: Subsector shareweight interpolation of upstream energy handling sectors" )
if( any( is.na( A21.subsector_interp$to.value ) ) ){
	L221.SubsectorInterp_en <- write_to_all_regions( A21.subsector_interp[ is.na( A21.subsector_interp$to.value ), ], names_SubsectorInterp, has.traded=T )
	}
if( any( !is.na( A21.subsector_interp$to.value ) ) ){
	L221.SubsectorInterpTo_en <- write_to_all_regions( A21.subsector_interp[ !is.na( A21.subsector_interp$to.value ), ], names_SubsectorInterpTo, has.traded=T )
	}

# 2c. Technology information
#Identification of stub technologies (assume those in global tech shareweight table include all techs)
printlog( "L221.StubTech_en: Identification of stub technologies of upstream energy handling sectors" )
L221.StubTech_en <- write_to_all_regions( A21.globaltech_shrwt, names_Tech, has.traded=F )
names( L221.StubTech_en ) <- names_StubTech

#Drop stub technologies for biomassOil techs that do not exist
L221.rm_biomassOil_techs <- A21.globaltech_shrwt[ A21.globaltech_shrwt$supplysector == "regional biomassOil", s_s_t ]
L221.rm_biomassOil_techs_R <- repeat_and_add_vector( L221.rm_biomassOil_techs, R, GCAM_region_names[[R]] )
L221.rm_biomassOil_techs_R <- add_region_name( L221.rm_biomassOil_techs_R )
L221.rm_biomassOil_techs_R <- subset( L221.rm_biomassOil_techs_R, paste( region, technology ) %!in% paste( A_regions$region, A_regions$biomassOil_tech ) )
L221.StubTech_en <- L221.StubTech_en[
      vecpaste( L221.StubTech_en[ c( "region", "stub.technology" ) ] ) %!in%
      vecpaste( L221.rm_biomassOil_techs_R[ c( "region", "technology" ) ] ), ]

#Coefficients of global technologies
printlog( "L221.GlobalTechCoef_en: Energy inputs and coefficients of global technologies for upstream energy handling" )
L221.globaltech_coef.melt <- interpolate_and_melt( A21.globaltech_coef, c( model_base_years, model_future_years ), value.name="coefficient" )
#Assign the columns "sector.name" and "subsector.name", consistent with the location info of a global technology
L221.globaltech_coef.melt[ c( "sector.name", "subsector.name" ) ] <- L221.globaltech_coef.melt[ c( "supplysector", "subsector" ) ]
L221.GlobalTechCoef_en <- L221.globaltech_coef.melt[ names_GlobalTechCoef ]

#Costs of global technologies
printlog( "L221.GlobalTechCost_en: Costs of global technologies for upstream energy handling" )
L221.globaltech_cost.melt <- interpolate_and_melt( A21.globaltech_cost, c( model_base_years, model_future_years ), value.name="input.cost" )
L221.globaltech_cost.melt[ c( "sector.name", "subsector.name" ) ] <- L221.globaltech_cost.melt[ c( "supplysector", "subsector" ) ]
L221.GlobalTechCost_en <- L221.globaltech_cost.melt[ names_GlobalTechCost ]

#Shareweights of global technologies
printlog( "L221.GlobalTechShrwt_en: Shareweights of global technologies for upstream energy handling" )
L221.globaltech_shrwt.melt <- interpolate_and_melt( A21.globaltech_shrwt, c( model_base_years, model_future_years ), value.name="share.weight" )
L221.globaltech_shrwt.melt[ c( "sector.name", "subsector.name" ) ] <- L221.globaltech_shrwt.melt[ c( "supplysector", "subsector" ) ]
L221.GlobalTechShrwt_en <- L221.globaltech_shrwt.melt[ c( names_GlobalTechYr, "share.weight" ) ]

#Keywords of global technologies
printlog( "L221.PrimaryConsKeyword_en: Primary energy consumption keywords" )
L221.PrimaryConsKeyword_en <- repeat_and_add_vector( A21.globaltech_keyword, Y, c( model_base_years, model_future_years ) )
L221.PrimaryConsKeyword_en[ c( "sector.name", "subsector.name" ) ] <- L221.PrimaryConsKeyword_en[ c( "supplysector", "subsector" ) ]
L221.PrimaryConsKeyword_en <- L221.PrimaryConsKeyword_en[ c( names_GlobalTechYr, "primary.consumption" ) ]

#Secondary feed outputs of biofuel production technologies
printlog( "L221.StubTechFractSecOut_en: Secondary (feed) outputs of global technologies for upstream (bio)energy" )
printlog( "NOTE: secondary outputs are only considered in future time periods" )
printlog( "NOTE: secondary outputs are only written for the regions/technologies where applicable, so the global tech database can not be used" )
# to get the appropriate region/tech combinations written out, first repeat by all regions, then subset as appropriate
L221.globaltech_secout_R <- repeat_and_add_vector( A21.globaltech_secout, R, GCAM_region_names[[R]] )
L221.globaltech_secout_R$sector <- calibrated_techs$sector[ match( L221.globaltech_secout_R$supplysector, calibrated_techs$minicam.energy.input ) ]

#For corn ethanol, region + sector is checked. For biodiesel, need to also include the region-specific feedstocks (to exclude palm oil biodiesel producing regions)
L221.globaltech_secout_R <- subset( L221.globaltech_secout_R,
                                    paste( L221.globaltech_secout_R[[R]], L221.globaltech_secout_R[[ "sector" ]] ) %in%
                                    paste( A_regions[[R]], A_regions$ethanol ) |
                                    paste( L221.globaltech_secout_R[[R]], L221.globaltech_secout_R[[ "sector" ]], L221.globaltech_secout_R[[ tech ]] ) %in%
                                    paste( A_regions[[R]], A_regions$biodiesel, A_regions$biomassOil_tech ) )
#Store these regions in a separate object
L221.ddgs_regions <- unique( L221.globaltech_secout_R[[R]] )
L221.globaltech_secout_R <- add_region_name( L221.globaltech_secout_R )
L221.StubTechFractSecOut_en <- interpolate_and_melt( L221.globaltech_secout_R, model_future_years, value.name="output.ratio" )
names( L221.StubTechFractSecOut_en )[ names( L221.StubTechFractSecOut_en ) == tech ] <- "stub.technology"
L221.StubTechFractSecOut_en <- L221.StubTechFractSecOut_en[ names_StubTechFractSecOut ]

# Fraction produced as a fn of DDGS/feedcake price
# Here we calculate the approximate price of feed in each region. Share of each feed type times the price of the commodity
# Subset only the feed items that are considered "FeedCrops"
L221.ag_Feed_Mt_R_C_Y <- subset( L108.ag_Feed_Mt_R_C_Y, GCAM_commodity %in% A_an_input_subsector$subsector[ A_an_input_subsector$supplysector == "FeedCrops" ] )
L221.ag_Feed_Mt_R_Yf <- aggregate( L221.ag_Feed_Mt_R_C_Y[ X_final_historical_year ], by = L221.ag_Feed_Mt_R_C_Y[ R ], sum )
L221.ag_FeedShares_R_C_Yf <- data.frame( L221.ag_Feed_Mt_R_C_Y[ c( R, "GCAM_commodity" ) ],
      L221.ag_Feed_Mt_R_C_Y[ X_final_historical_year ] / L221.ag_Feed_Mt_R_Yf[[X_final_historical_year]][
          match( L221.ag_Feed_Mt_R_C_Y[[R]], L221.ag_Feed_Mt_R_Yf[[R]] ) ] )
L221.ag_FeedShares_R_C_Yf$price <- L132.ag_an_For_Prices$calPrice[ match( L221.ag_FeedShares_R_C_Yf$GCAM_commodity, L132.ag_an_For_Prices$GCAM_commodity ) ]
L221.ag_FeedShares_R_C_Yf$feed_price <- L221.ag_FeedShares_R_C_Yf$price * L221.ag_FeedShares_R_C_Yf[[X_final_historical_year]]
L221.ag_FeedPrice_R_Yf <- aggregate( L221.ag_FeedShares_R_C_Yf["feed_price"], by = L221.ag_FeedShares_R_C_Yf[R], sum )
L221.ag_FeedPrice_R_Yf <- add_region_name( L221.ag_FeedPrice_R_Yf)

# Indicate the price points for the DDG/feedcake commodity
# This is important for ensuring that the secondary output of feedcrops from the bio-refinery feedstock pass-through sectors
# does not exceed the indigenous market demand for feed in the animal-based commodity production sectors
printlog( "L221.StubTechFractProd_en: cost curve points for producing secondary output feedcrops" )
L221.StubTechFractProd_en <- L221.StubTechFractSecOut_en[ names( L221.StubTechFractSecOut_en ) != "output.ratio" ]
L221.StubTechFractProd_en$P0 <- 0
L221.StubTechFractProd_en$P1 <- round( L221.ag_FeedPrice_R_Yf$feed_price[
  match( L221.StubTechFractProd_en$region, L221.ag_FeedPrice_R_Yf$region ) ],
  digits_cost )
L221.StubTechFractProd_en <- melt( L221.StubTechFractProd_en, measure.vars = c( "P0", "P1" ), value.name = "price" )
L221.StubTechFractProd_en$fraction.produced <- as.numeric( sub( "P", "", L221.StubTechFractProd_en$variable ) )
L221.StubTechFractProd_en$variable <- NULL

# Final tables for feedcrop secondary output: the resource
L221.DepRsrc_en <- repeat_and_add_vector( A21.rsrc_info, R, L221.ddgs_regions )
L221.DepRsrc_en <- add_region_name( L221.DepRsrc_en )[ names_DepRsrc ]
L221.DepRsrc_en$market[ L221.DepRsrc_en$market == "regional" ] <- L221.DepRsrc_en$region[ L221.DepRsrc_en$market == "regional" ]
L221.rsrc_prices <- interpolate_and_melt( A21.rsrc_info, model_base_years, digits = digits_cost, value.name = "price" )
L221.DepRsrcPrice_en <- repeat_and_add_vector( L221.rsrc_prices, R, L221.ddgs_regions )
L221.DepRsrcPrice_en <- add_region_name( L221.DepRsrcPrice_en )[ names_DepRsrcPrice ]

#Coefficients of traded technologies
printlog( "L221.TechCoef_en_Traded: Energy inputs, coefficients, and market names of traded technologies for upstream energy handling" )
L221.tradedtech_coef.melt <- interpolate_and_melt( A21.tradedtech_coef, c( model_base_years, model_future_years ), value.name="coefficient" )
L221.TechCoef_en_Traded <- write_to_all_regions( L221.tradedtech_coef.melt, names_TechCoef, has.traded = T, apply.to = "all", set.market = T )

#Costs of traded technologies
printlog( "L221.TechCost_en_Traded: Costs of traded technologies for upstream energy handling" )
L221.tradedtech_cost.melt <- interpolate_and_melt( A21.tradedtech_cost, c( model_base_years, model_future_years ), value.name="input.cost" )
L221.TechCost_en_Traded <- write_to_all_regions( L221.tradedtech_cost.melt, names_TechCost, has.traded = T, apply.to = "all", set.market = F )

#Shareweights of traded technologies
printlog( "L221.TechShrwt_en_Traded: Shareweights of traded technologies for upstream energy handling" )
L221.tradedtech_shrwt.melt <- interpolate_and_melt( A21.tradedtech_shrwt, c( model_base_years, model_future_years ), value.name="share.weight" )
L221.TechShrwt_en_Traded <- write_to_all_regions( L221.tradedtech_shrwt.melt, c( names_TechYr, "share.weight" ), has.traded = T, apply.to = "all", set.market = F )

#2b. Calibration and region-specific data
printlog( "L221.StubTechCoef_unoil: Coefficient and market name of stub technologies for importing traded unconventional oil" )
L221.StubTechCoef_unoil <- subset( L221.globaltech_coef.melt, minicam.energy.input %in% L221.TechShrwt_en_Traded$supplysector )
L221.StubTechCoef_unoil$stub.technology <- L221.StubTechCoef_unoil$technology
L221.StubTechCoef_unoil <- write_to_all_regions( L221.StubTechCoef_unoil, names_StubTechCoef[ names_StubTechCoef != "market.name" ] )
L221.StubTechCoef_unoil$market.name <- GCAM_region_names$region[1]

L221.Prod_EJ_R_unoil_Yh.melt <- melt( L111.Prod_EJ_R_F_Yh[ grep( "unconventional", L111.Prod_EJ_R_F_Yh$fuel ),
      c( "GCAM_region_ID", X_model_base_years ) ], id.vars = "GCAM_region_ID" )
L221.Prod_EJ_R_unoil_Yh.melt <- add_region_name( L221.Prod_EJ_R_unoil_Yh.melt )
L221.Prod_EJ_R_unoil_Yh.melt$year <- substr( L221.Prod_EJ_R_unoil_Yh.melt$variable, 2, 5 )

printlog( "L221.Production_unoil: Calibrated production of unconventional oil" )
L221.Production_unoil <- subset( L221.TechCoef_en_Traded, supplysector == "traded unconventional oil" & year %in% model_base_years )
L221.Production_unoil$calOutputValue <- round(
      L221.Prod_EJ_R_unoil_Yh.melt$value[
         match( paste( L221.Production_unoil$market.name, L221.Production_unoil$year ),
                paste( L221.Prod_EJ_R_unoil_Yh.melt$region, L221.Prod_EJ_R_unoil_Yh.melt$year ) ) ],
      digits_calOutput )
L221.Production_unoil <- L221.Production_unoil[ c( names_TechYr, "calOutputValue" ) ]
L221.Production_unoil$calOutputValue[ is.na( L221.Production_unoil$calOutputValue ) ] <- 0             
L221.Production_unoil$year.share.weight <- L221.Production_unoil$year
L221.Production_unoil$subsector.share.weight <- ifelse( L221.Production_unoil$calOutputValue > 0, 1, 0 )
L221.Production_unoil$share.weight <- ifelse( L221.Production_unoil$calOutputValue >0, 1, 0 )

#Unconventional oil demand
L221.in_EJ_R_TPES_unoil_Yh.melt <- melt( L121.in_EJ_R_TPES_unoil_Yh, id.vars = R_S_F )
L221.in_EJ_R_TPES_unoil_Yh.melt <- add_region_name( L221.in_EJ_R_TPES_unoil_Yh.melt )
L221.in_EJ_R_TPES_unoil_Yh.melt$year <- substr( L221.in_EJ_R_TPES_unoil_Yh.melt$variable, 2, 5 )

printlog( "L221.StubTechProd_oil_unoil: Calibrated demand of unconventional oil" )
L221.StubTechProd_oil_unoil <- subset( L221.StubTech_en, supplysector == "regional oil" & subsector == "unconventional oil" )
L221.StubTechProd_oil_unoil <- repeat_and_add_vector( L221.StubTechProd_oil_unoil, "year", model_base_years )
L221.StubTechProd_oil_unoil$calOutputValue <- round(
      L221.in_EJ_R_TPES_unoil_Yh.melt$value[
         match( paste( L221.StubTechProd_oil_unoil$region, L221.StubTechProd_oil_unoil$year ),
                paste( L221.in_EJ_R_TPES_unoil_Yh.melt$region, L221.in_EJ_R_TPES_unoil_Yh.melt$year ) ) ],
      digits_calOutput )
L221.StubTechProd_oil_unoil$year.share.weight <- L221.StubTechProd_oil_unoil$year
L221.StubTechProd_oil_unoil$subsector.share.weight <- ifelse( L221.StubTechProd_oil_unoil$calOutputValue > 0, 1, 0 )
L221.StubTechProd_oil_unoil$share.weight <- ifelse( L221.StubTechProd_oil_unoil$calOutputValue > 0, 1, 0 )

#Crude oil demand
L221.in_EJ_R_TPES_crude_Yh.melt <- melt( L121.in_EJ_R_TPES_crude_Yh, id.vars = R_S_F )
L221.in_EJ_R_TPES_crude_Yh.melt <- add_region_name( L221.in_EJ_R_TPES_crude_Yh.melt )
L221.in_EJ_R_TPES_crude_Yh.melt$year <- substr( L221.in_EJ_R_TPES_crude_Yh.melt$variable, 2, 5 )

printlog( "L221.StubTechProd_oil_crude: Calibrated demand of crude oil" )
L221.StubTechProd_oil_crude <- subset( L221.StubTech_en, supplysector == "regional oil" & subsector == "crude oil" )
L221.StubTechProd_oil_crude <- repeat_and_add_vector( L221.StubTechProd_oil_crude, "year", model_base_years )
L221.StubTechProd_oil_crude$calOutputValue <- round(
      L221.in_EJ_R_TPES_crude_Yh.melt$value[
         match( paste( L221.StubTechProd_oil_crude$region, L221.StubTechProd_oil_crude$year ),
                paste( L221.in_EJ_R_TPES_crude_Yh.melt$region, L221.in_EJ_R_TPES_crude_Yh.melt$year ) ) ],
      digits_calOutput )
L221.StubTechProd_oil_crude$year.share.weight <- L221.StubTechProd_oil_crude$year
L221.StubTechProd_oil_crude$subsector.share.weight <- ifelse( L221.StubTechProd_oil_crude$calOutputValue > 0, 1, 0 )
L221.StubTechProd_oil_crude$share.weight <- ifelse( L221.StubTechProd_oil_crude$calOutputValue > 0, 1, 0 )

printlog( "L221.StubTechShrwt_bio: region-specific technology shareweights for biomassOil passthrough sector")
L221.globaltech_shrwt_bio <- interpolate_and_melt( subset( A21.globaltech_shrwt, supplysector == "regional biomassOil" ),
      c( model_base_years, model_future_years ), value.name="share.weight" )
L221.StubTechShrwt_bio <- write_to_all_regions( L221.globaltech_shrwt_bio, c( "region", names( L221.globaltech_shrwt_bio ) ) )
L221.StubTechShrwt_bio$stub.technology <- L221.StubTechShrwt_bio$technology
L221.StubTechShrwt_bio$share.weight <- ifelse(
      vecpaste( L221.StubTechShrwt_bio[ c( "region", "stub.technology" ) ] ) %in% vecpaste( A_regions[ c( "region", "biomassOil_tech" ) ] ),
      1, 0 )
L221.StubTechShrwt_bio <- L221.StubTechShrwt_bio[ c( names_StubTechYr, "share.weight" ) ]
L221.StubTechShrwt_bio <- subset( L221.StubTechShrwt_bio,
      vecpaste( L221.StubTechShrwt_bio[ c( "stub.technology", "year", "share.weight" ) ] ) != 
      vecpaste( L221.globaltech_shrwt_bio[ c( "technology", "year", "share.weight" ) ] ) )

###For regions with no agricultural and land use sector (Taiwan), need to remove the passthrough supplysectors for first-gen biofuels
ag_en <- c( "regional corn for ethanol", "regional sugar for ethanol", "regional biomassOil" )
for( curr_table in names( L221.SectorLogitTables ) ) {
    if( curr_table != "EQUIV_TABLE" ) {
        L221.SectorLogitTables[[ curr_table ]]$data <- L221.SectorLogitTables[[ curr_table ]]$data[
            vecpaste( L221.SectorLogitTables[[ curr_table ]]$data[ c( "region", supp ) ] ) %!in%
            paste( no_aglu_regions, ag_en ), ]
    }
}
L221.Supplysector_en <- L221.Supplysector_en[ vecpaste( L221.Supplysector_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]
for( curr_table in names( L221.SubsectorLogitTables ) ) {
    if( curr_table != "EQUIV_TABLE" ) {
        L221.SubsectorLogitTables[[ curr_table ]]$data <- L221.SubsectorLogitTables[[ curr_table ]]$data[
            vecpaste( L221.SubsectorLogitTables[[ curr_table ]]$data[ c( "region", supp ) ] ) %!in%
            paste( no_aglu_regions, ag_en ), ]
    }
}
L221.SubsectorLogit_en <- L221.SubsectorLogit_en[ vecpaste( L221.SubsectorLogit_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]
if( exists( "L221.SubsectorShrwt_en" ) ){
	L221.SubsectorShrwt_en <- L221.SubsectorShrwt_en[ vecpaste( L221.SubsectorShrwt_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]
}
if( exists( "L221.SubsectorShrwtFllt_en" ) ){
	L221.SubsectorShrwtFllt_en <- L221.SubsectorShrwtFllt_en[ vecpaste( L221.SubsectorShrwtFllt_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]
}
if( exists( "L221.SubsectorInterp_en" ) ) {
	L221.SubsectorInterp_en <- L221.SubsectorInterp_en[ vecpaste( L221.SubsectorInterp_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]
}
if( exists( "L221.SubsectorInterpTo_en" ) ) {
	L221.SubsectorInterpTo_en <- L221.SubsectorInterpTo_en[ vecpaste( L221.SubsectorInterpTo_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]
}
L221.StubTech_en <- L221.StubTech_en[ vecpaste( L221.StubTech_en[ c( "region", supp ) ] ) %!in% paste( no_aglu_regions, ag_en ), ]

# -----------------------------------------------------------------------------
# 3. Write all csvs as tables, and paste csv filenames into a single batch XML file
for( curr_table in names ( L221.SectorLogitTables) ) {
write_mi_data( L221.SectorLogitTables[[ curr_table ]]$data, L221.SectorLogitTables[[ curr_table ]]$header,
    "ENERGY_LEVEL2_DATA", paste0("L221.", L221.SectorLogitTables[[ curr_table ]]$header ), "ENERGY_XML_BATCH",
    "batch_en_supply.xml" )
}
write_mi_data( L221.Supplysector_en, IDstring="Supplysector", domain="ENERGY_LEVEL2_DATA", fn="L221.Supplysector_en",
               batch_XML_domain="ENERGY_XML_BATCH", batch_XML_file="batch_en_supply.xml" ) 
write_mi_data( L221.SectorUseTrialMarket_en, "SectorUseTrialMarket", "ENERGY_LEVEL2_DATA", "L221.SectorUseTrialMarket_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" ) 
for( curr_table in names ( L221.SubsectorLogitTables ) ) {
write_mi_data( L221.SubsectorLogitTables[[ curr_table ]]$data, L221.SubsectorLogitTables[[ curr_table ]]$header,
    "ENERGY_LEVEL2_DATA", paste0("L221.", L221.SubsectorLogitTables[[ curr_table ]]$header ), "ENERGY_XML_BATCH",
    "batch_en_supply.xml" )
}
write_mi_data( L221.SubsectorLogit_en, "SubsectorLogit", "ENERGY_LEVEL2_DATA", "L221.SubsectorLogit_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" ) 
if( exists( "L221.SubsectorShrwt_en" ) ){
	write_mi_data( L221.SubsectorShrwt_en, "SubsectorShrwt", "ENERGY_LEVEL2_DATA", "L221.SubsectorShrwt_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
	}
if( exists( "L221.SubsectorShrwtFllt_en" ) ){
	write_mi_data( L221.SubsectorShrwtFllt_en, "SubsectorShrwtFllt", "ENERGY_LEVEL2_DATA", "L221.SubsectorShrwtFllt_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" ) 
	}
if( exists( "L221.SubsectorInterp_en" ) ) {
	write_mi_data( L221.SubsectorInterp_en, "SubsectorInterp", "ENERGY_LEVEL2_DATA", "L221.SubsectorInterp_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
	}
if( exists( "L221.SubsectorInterpTo_en" ) ) {
	write_mi_data( L221.SubsectorInterpTo_en, "SubsectorInterpTo", "ENERGY_LEVEL2_DATA", "L221.SubsectorInterpTo_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
	}
write_mi_data( L221.StubTech_en, "StubTech", "ENERGY_LEVEL2_DATA", "L221.StubTech_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.GlobalTechCoef_en, "GlobalTechCoef", "ENERGY_LEVEL2_DATA", "L221.GlobalTechCoef_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.GlobalTechCost_en, "GlobalTechCost", "ENERGY_LEVEL2_DATA", "L221.GlobalTechCost_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.GlobalTechShrwt_en, "GlobalTechShrwt", "ENERGY_LEVEL2_DATA", "L221.GlobalTechShrwt_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.PrimaryConsKeyword_en, "PrimaryConsKeyword", "ENERGY_LEVEL2_DATA", "L221.PrimaryConsKeyword_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.StubTechFractSecOut_en, "StubTechFractSecOut", "ENERGY_LEVEL2_DATA", "L221.StubTechFractSecOut_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.StubTechFractProd_en, "StubTechFractProd", "ENERGY_LEVEL2_DATA", "L221.StubTechFractProd_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.DepRsrc_en, "DepRsrc", "ENERGY_LEVEL2_DATA", "L221.DepRsrc_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.DepRsrcPrice_en, "DepRsrcPrice", "ENERGY_LEVEL2_DATA", "L221.DepRsrcPrice_en", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.TechCoef_en_Traded, "TechCoef", "ENERGY_LEVEL2_DATA", "L221.TechCoef_en_Traded", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.TechCost_en_Traded, "TechCost", "ENERGY_LEVEL2_DATA", "L221.TechCost_en_Traded", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.TechShrwt_en_Traded, "TechShrwt", "ENERGY_LEVEL2_DATA", "L221.TechShrwt_en_Traded", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.StubTechCoef_unoil, "StubTechCoef", "ENERGY_LEVEL2_DATA", "L221.StubTechCoef_unoil", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.Production_unoil, "Production", "ENERGY_LEVEL2_DATA", "L221.Production_unoil", "ENERGY_XML_BATCH", "batch_en_supply.xml" ) 
write_mi_data( L221.StubTechProd_oil_unoil, "StubTechProd", "ENERGY_LEVEL2_DATA", "L221.StubTechProd_oil_unoil", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.StubTechProd_oil_crude, "StubTechProd", "ENERGY_LEVEL2_DATA", "L221.StubTechProd_oil_crude", "ENERGY_XML_BATCH", "batch_en_supply.xml" )
write_mi_data( L221.StubTechShrwt_bio, "StubTechShrwt", "ENERGY_LEVEL2_DATA", "L221.StubTechShrwt_bio", "ENERGY_XML_BATCH", "batch_en_supply.xml" )

insert_file_into_batchxml( "ENERGY_XML_BATCH", "batch_en_supply.xml", "ENERGY_XML_FINAL", "en_supply.xml", "", xml_tag="outFile" )

logstop()


