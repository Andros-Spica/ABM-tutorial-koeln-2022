;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  MesaraTrade - model for the tutorial ABM in archaeology at the University of Koeln
;;  Based on modified parts of:
;;  PondTrade
;;  available at https://github.com/Andros-Spica/PondTrade
;;  and
;;  Soil Water Balance model (NetLogo implementation)
;;  Land model
;;  Copyright (C) 2022 Andreas Angourakis (andros.spica@gmail.com)
;;  available at https://www.github.com/Andros-Spica/indus-village-model
;;  implementing the Soil Water Balance model from Wallach et al. 2006 'Working with dynamic crop models' (p. 24-28 and p. 138-144).
;;  This implementation uses parts of the Weather model to simulate input variables (i.e., temperature, solar radiation, precipitation, evapotranspiration)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

extensions [ csv gis ]

;;;;;;;;;;;;;;;;;
;;;;; BREEDS ;;;;
;;;;;;;;;;;;;;;;;

breed [ flowHolders flowHolder ]
breed [ sites site ]
breed [ settlements settlement ]
breed [ traders trader ]

;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

globals
[
  patchesWithElevationData
  noElevationDataTag
  maxElevation

  width
  height

  ;;; GIS data holders
  sitesData_EMIII-MMIA
  sitesData_MMIB
  elevationData
  riversData

  ;;; weather input data
  weatherInputData_firstYear
  weatherInputData_lastYear
  weatherInputData_YEARS
  weatherInputData_yearLengthInDays
  weatherInputData_DOY
  weatherInputData_YEAR-DOY
  weatherInputData_solarRadiation
  weatherInputData_precipitation
  weatherInputData_temperature
  weatherInputData_maxTemperature
  weatherInputData_minTemperature

  ;;; default constants

  MUF ; Water Uptake coefficient (mm^3.mm^-3)
  WP ; Water content at wilting Point (cm^3.cm^-3)

  ;;;; ETr
  albedo_min
  albedo_max

  ;;;; Soil Water Balance model global parameters
  WHC_min
  WHC_max
  DC_min
  DC_max
  z_min
  z_max
  CN_min
  CN_max

  ;;; variables
  ;;;; time tracking
  currentYear
  currentDayOfYear

  maxFlowAccumulation

  routes

  ;;;; main (these follow a seasonal pattern and apply for all patches)

  T ; average temperature of current day (ºC)
  T_max ; maximum temperature of current day (ºC)
  T_min ; minimum temperature of current day (ºC)

  solarRadiation ; solar radiation of current day (MJ m-2)

  RAIN ; precipitation of current day (mm)
  precipitation_yearSeries
  precipitation_cumYearSeries

  ;;; Output
  patchesCount
  coastalLandPatchesCount

  traderCount

  meanTraderCargoValue
  minTraderCargoValue
  maxTraderCargoValue

  minSettlementSize
  maxSettlementSize
  mainHub

  meanTotalPathCostOfActiveRoutes
  minTotalPathCostOfActiveRoutes
  maxTotalPathCostOfActiveRoutes

  meanRedTrait stdDevRedTrait modesRedTrait
  meanGreenTrait stdDevGreenTrait modesGreenTrait
  meanBlueTrait stdDevBlueTrait modesBlueTrait

  meanLandTechTrait stdDevLandTechTrait modesLandTechTrait
  meanPortTechTrait stdDevPortTechTrait modesPortTechTrait

  meanSizeDecayTrait stdDevSizeDecayTrait modesSizeDecayTrait
  meanStockDecayTrait stdDevStockDecayTrait modesStockDecayTrait
  meanProductionTrait stdDevProductionTrait modesProductionTrait

  meanFreqOverQualTrait stdDevFreqOverQualTrait modesFreqOverQualTrait
  meanTransmissionTrait stdDevTransmissionTrait modesTransmissionTrait
  meanMutationTrait stdDevMutationTrait modesMutationTrait
]

sites-own
[
  name
  siteType
  period
]

settlements-own
[
  sizeLevel
  currentNumberOfTraders potentialNumberOfTraders
  stock
  culturalVector
  catchmentArea
  ARIDinCatchmentArea
]

traders-own
[
  isActivated
  base route destination direction lastPosition
  cargoValue
  culturalSample
]

patches-own
[
  elevation ; elevation above sea level [m]

  flow_direction        ; the numeric code for the (main) direction of flow or
                        ; drainage within the land unit.
                        ; Following Jenson & Domingue (1988) convention:
                        ; NW = 64,   N = 128,        NE = 1,
                        ; W = 32,     <CENTRE>,   E = 2,
                        ; SW = 16,     S = 8,          SE = 4

  flow_receive          ; Boolean variable stating whether or not the land unit receives
                        ; the flow of a neighbour.

  flow_accumulation     ; the amount of flow units accumulated in the land unit.
                        ; A Flow unit is the volume of runoff water flowing from one land unit
                        ; to another (assumed constant and without losses).
  flow_accumulationState ; the state of the land unit regarding the calculation of flow
                        ; accumulation (auxiliary variable).

  isRiver

  pathCost

  ;;;; soil
  DC ; Drainage coefficient (mm^3 mm^-3).
  z ; root zone depth (mm).
  CN ; Runoff curve number.
  FC ; Water content at field capacity (cm^3.cm^-3)
  WHC ; Water Holding Capacity of the soil (cm^3.cm^-3). Typical range from 0.05 to 0.25

  ARID ; ARID index after Woli et al. 2012, ranging form 0 (no water shortage) to 1 (extreme water shortage)
  WAT ; Water content in the soil profile for the rooting depth (mm)
  WATp ; Volumetric Soil Water content (fraction : mm.mm-1). calculated as WAT/z

  ;;;; cover
  albedo ; canopy reflection or albedo
  netSolarRadiation ; net solar radiation discount canopy reflection or albedo
  ETr ; reference evapotranspiration

  ARID_modifier ; modifier coefficient based on the relative value of flow_accumulation
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  clear-all

  ; --- loading/testing parameters -----------

  import-map-with-flows ; import-world must be the first step

  set-constants

  set-parameters

  import-routes-from-file

  ; --- core procedures ----------------------

  setup-patches

  setup-settlements

  create-traders-per-settlement

  set currentYear weatherInputData_firstYear
  set currentDayOfYear 1

  ;;; values are taken from input data
  set-day-weather-from-input-data currentDayOfYear currentYear

  ask patchesWithElevationData [ update-WAT ]

  ; --- display & output handling ------------------------

  update-output

  refresh-view

  paint-routes

  ; -- time -------------------------------------

  reset-ticks

end

to set-constants

  ; "constants" are variables that will not be explored as parameters
  ; and may be used during a simulation.

  ; MUF : Water Uptake coefficient (mm^3 mm^-3)
  set MUF 0.096

  ; WP : Water content at wilting Point (cm^3.cm^-3)
  set WP 0.06

end

to set-parameters

  ; set random seed
  random-seed randomSeed

  ;;; load weather input data from file
  load-weather-input-data-table

  parameters-check

  ;;; weather parameters are left with default values, but effectively ignored given that input weather is used.

  set albedo_min 1E-6 + random-float 0.3
  set albedo_max albedo_min + random-float 0.3

  ;;; Soil Water Balance model
  set WHC_min random-float 0.1
  set WHC_max WHC_min + random-float 0.1
  set DC_min 1E-6 + random-float 0.45
  set DC_max DC_min + random-float 0.45
  set z_min random-float 1000
  set z_max z_min + random-float 1000
  set CN_min random-float 40
  set CN_max CN_min + random-float 50

end

to parameters-check

  ;;; check if values were reset to 0 (NetLogo does that from time to time...!)
  ;;; and set default values (assuming they are not 0)

  if (par_albedo_min = 0)                                        [ set par_albedo_min                              0.1 ]
  if (par_albedo_max = 0)                                        [ set par_albedo_max                              0.5 ]

  if (water-holding-capacity_min = 0)                            [ set water-holding-capacity_min                    0.05 ]
  if (water-holding-capacity_max = 0)                            [ set water-holding-capacity_max                    0.25 ]
  if (drainage-coefficient_min = 0)                              [ set drainage-coefficient_min                      0.3 ]
  if (drainage-coefficient_max = 0)                              [ set drainage-coefficient_max                      0.7 ]
  if (root-zone-depth_min = 0)                                   [ set root-zone-depth_min                         200 ]
  if (root-zone-depth_max = 0)                                   [ set root-zone-depth_max                        2000 ]
  if (runoff-curve_min = 0)                                      [ set runoff-curve_min                             30 ]
  if (runoff-curve_max = 0)                                      [ set runoff-curve_max                             80 ]

end

to parameters-to-default

  ;;; set parameters to a default value
  set par_albedo_min                                            0.1
  set par_albedo_max                                            0.5

  set water-holding-capacity_min                                0.05
  set water-holding-capacity_max                                0.25
  set drainage-coefficient_min                                  0.3
  set drainage-coefficient_max                                  0.7
  set root-zone-depth_min                                     200
  set root-zone-depth_max                                    2000
  set runoff-curve_min                                         30
  set runoff-curve_max                                         80

end

to setup-patches

  setup-soil-water-properties

  setup-ARID-modifier

  assign-path-cost

end

to import-map-with-flows

  import-world "data/terrainWithFlows/BlockC_module2_flows world.csv"

  ;;; reduce patch size in pixels
  set-patch-size 3

end

to setup-soil-water-properties

  ask patchesWithElevationData
  [
    set albedo albedo_min + random-float (albedo_max - albedo_min)

    ; Water Holding Capacity of the soil (cm^3 cm^-3).
    set WHC WHC_min + random-float (WHC_max - WHC_min)
    ; DC :  Drainage coefficient (mm^3 mm^-3)
    set DC DC_min + random-float (DC_max - DC_min)
    ; z : root zone depth (mm)
    set z z_min + random (z_max - z_min)
    ; CN : Runoff curve number
    set CN CN_min + random (CN_max - CN_max)

    ; FC : Water content at field capacity (cm^3.cm^-3)
    set FC WP + WHC
    ; WAT0 : Initial Water content (mm)
    set WAT z * FC
  ]

end

to setup-ARID-modifier

  ask patchesWithElevationData
  [
    set ARID_modifier (1 - ARID-decrease-per-flow-accumulation * (flow_accumulation / maxFlowAccumulation))
  ]

end

to assign-path-cost

  ask patches with [elevation = noElevationDataTag] [ set pathCost 9999 ] ;;; this makes routes crossing patches with no elevation data extremely unlikely

  ask patchesWithElevationData
  [
    let myValidNeighborsAndI (patch-set self (neighbors with [elevation > noElevationDataTag]))

    ifelse (count myValidNeighborsAndI > 1)
    [
      set pathCost standard-deviation [elevation] of myValidNeighborsAndI
    ]
    [
      set pathCost 1
    ]
  ]

end

to setup-settlements

  ask sites with [period = simulation-period]
  [
    set shape "dot"
    set size 5

    hatch-settlements 1
    [
      set sizeLevel 1
      set stock 0

      set culturalVector extract-rgb color ; 0#, 1# and 2#
      ; We add seven continuos cultural traits to the neutral RGB traits,
      ; representing their attitude and ability involving
      ; aspects we previously fixed as parameters and one variable:
      ; 3# relativePathCostInLand (normal distribution around global parameter)
      set culturalVector lput (random-normal 0 landTechVariation) culturalVector
      ; 4# relativePathCostInPort (normal distribution around global parameter)
      set culturalVector lput (random-normal 0 portTechVariation) culturalVector
      ; 5# settlementSizeDecayRate [0 - maxSettlementSizeDecayRate)
      set culturalVector lput (random-float maxSettlementSizeDecayRate) culturalVector
      ; 6# stockDecayRate [0 - maxStockDecayRate)
      set culturalVector lput (random-float maxStockDecayRate) culturalVector
      ; 7# produtionRate [0 - maxProductionRate)
      set culturalVector lput (random-float maxProductionRate) culturalVector
      ; 8# frequencyOverQuality [0 - 1)
      set culturalVector lput (random-float 1) culturalVector
      ; 9# traitTransmissionRate [0 - maxTraitTransmissionRate) *** now, it means specifically the 'openess' of a settlement towards other variants of a trait
      set culturalVector lput (random-float maxTraitTransmissionRate) culturalVector
      ; 10# mutationVariation [0 - maxMutationVariation)
      set culturalVector lput (random-float maxMutationVariation) culturalVector

      ; replace the land path cost with the port pathCost
      ask patch-here [ set pathCost relativePathCostInPort ]

      ;;; move the settlement to the exact center of the patch
      set xcor [pxcor] of patch-here
      set ycor [pycor] of patch-here

      set shape "circle 2"
      set size 5
    ]
  ]

end

to create-traders-per-settlement

  ask settlements
  [
    let thisSettlement self ; to avoid the confusion of nested agent queries

    set potentialNumberOfTraders get-potential-number-of-traders

    hatch-traders potentialNumberOfTraders ; use the sizeLevel variable as the number of traders based in the settlement
    [
      setup-trader thisSettlement
    ]

    set currentNumberOfTraders get-current-number-of-traders
  ]

end

to setup-trader [ baseSettlement ]

  set base baseSettlement
  set isActivated true

  ; give meaningful display related to base
  set shape "person"
  set color [color] of base
  set size 3

  choose-destination

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go

  ; --- core procedures -------------------------

  ;;; values are taken from input data
  set-day-weather-from-input-data currentDayOfYear currentYear

  ask patchesWithElevationData [ update-WAT modify-ARID ]

  update-traders

  update-settlements

  ; --- output handling ------------------------

  update-output

  refresh-view

  ; -- time -------------------------------------

  advance-time

  tick

  ; --- stop conditions -------------------------

  if (currentYear = weatherInputData_lastYear and currentDayOfYear = last weatherInputData_yearLengthInDays) [stop]

end

;;; GLOBAL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to advance-time

  set currentDayOfYear currentDayOfYear + 1
  if (currentDayOfYear > item (currentYear - weatherInputData_firstYear) weatherInputData_yearLengthInDays)
  [
    set currentYear currentYear + 1
    set currentDayOfYear 1
  ]

end

;;; traders and settlements ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-traders

  let activeTraders traders with [isActivated]
  let tradersInBase activeTraders with [is-in-base]
  let tradersInDestination activeTraders with [is-in-destination]

  ; UPDATE LAST POSITION
  ask activeTraders
  [
    ; update lastPosition if in a patch centre
    if ((xcor = [pxcor] of patch-here) and (ycor = [pycor] of patch-here))
    [
      set lastPosition patch-here
    ]
  ]

  ; UNLOAD
  ask (turtle-set tradersInBase tradersInDestination) with [cargoValue > 0]
  [
    ; unload cargo (changes sizeLevel)
    unload-cargo
  ]

  ; CHECK if the trader can be sustained when in the base
  ask tradersInBase
  [
    if ([potentialNumberOfTraders < currentNumberOfTraders] of base)
    [
      ; the current number of traders cannot be sustained
      set isActivated false
      ; update currentNumberOfTraders of base
      ask base [ set currentNumberOfTraders get-current-number-of-traders ]
    ]
  ]

  set activeTraders traders with [isActivated] ; update active traders
  set tradersInBase tradersInBase with [isActivated] ; update traders in base

  ; LOAD
  ask (turtle-set tradersInBase tradersInDestination)
  [
    ; load cargo (changes stock)
    load-cargo
  ]

  ; CHOOSE DESTINATION
  ask tradersInBase with [cargoValue > 0]
  [
    ; update the destination whenever in the base settlement and there is cargo to transport
    choose-destination
  ]

  ; FIND DIRECTION in route
  ask (turtle-set tradersInBase tradersInDestination)
  [
    find-direction
  ]

  ; MOVE towards the next position in the route
  ask activeTraders with [cargoValue > 0]
  [
    ; move following the route when there is cargo to transport
    move-to-destination
  ]

end

to choose-destination ; ego = trader

  let thisTrader self

  ; get routes connecting the base settlement
  let routesFromBase get-routes-to-settlement [base] of thisTrader

  ; order these routes by benefit/cost ratio
  set routesFromBase sort-by [ [?1 ?2] -> benefit-cost-of-route ?1 thisTrader > benefit-cost-of-route ?2 thisTrader ] routesFromBase

  ; print the options available
;  foreach routesFromBase
;  [
;    print "==============================================================="
;    print "route between:"
;    print [who] of get-origin-and-destination ?
;    print "has the benefit-cost ratio of:"
;    print benefit-cost-of-route ?
;  ]
;  print "-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x"

  ; select the one with higher benefit/cost ratio
  set route first routesFromBase

  ; get the settlement of destination
  set destination one-of (get-origin-and-destination route) with [who != [who] of ([base] of thisTrader)]

end

to find-direction ; ego = trader

  ; find where in the route list is the trader
  let currentPosition position lastPosition route

  ; set direction if in a settlement
  ifelse (currentPosition = 0) ; in the first extreme of the route list
  [
    ; move in the route list towards larger index numbers
    set direction 1
  ]
  [
    if (currentPosition = (length route - 1)) ; in the last extreme of the route list
    [
      ; move in the route list towards smaller index numbers
      set direction -1
    ]
  ]
  ; else the trader is in route to either the base or the destination

end

to move-to-destination ; ego = trader

  ; find where in the route list is the trader
  let currentPosition position lastPosition route

  ; move through the route following direction
  let targetPatch item (currentPosition + direction) route
  ;move-to targetPatch ; constant travel time (1 patch per tick)
  facexy ([pxcor] of targetPatch) ([pycor] of targetPatch)

  forward min (
    list
    (1 / get-path-cost patch-here self) ; the maximum distance in a tick in the current patch
    (distancexy ([pxcor] of targetPatch) ([pycor] of targetPatch)) ; the distance to the target patch
    )

end

to-report is-in-base ; ego = trader

  report (xcor = [xcor] of base) and (ycor = [ycor] of base) ; if the trader arrived at the centre of the base patch

end

to-report is-in-destination ; ego = trader

  report (xcor = [xcor] of destination) and (ycor = [ycor] of destination) ; if the trader arrived at the centre of the destination patch

end

to unload-cargo ; ego = trader

  let thisTrader self
  let settlementHere one-of settlements-here

  ; unload cargo
  ask settlementHere [ add-trade-effect thisTrader ]

end

to load-cargo ; ego = trader

  let settlementHere one-of settlements-here

  ; load cargo
  set cargoValue [stock] of settlementHere
  ask settlementHere [ set stock 0 ] ; empty the settlement stock

  set culturalSample [culturalVector] of settlementHere

end

to update-settlements

  ask settlements
  [
    let thisSettlement self

    ; the sizeLevel of settlements decays with a constant rate, up to 1 (minimum)
    set sizeLevel max (list 1 (sizeLevel * (1 - ((item 5 culturalVector) / 100)) ) )
    ; production in stock also decays with a constant rate
    set stock stock * (1 - ((item 6 culturalVector) / 100))
    ; prodution is generated in proportion to sizeLevel, following a constant rate and the average ARID within the settlement catchment area
    update-ARIDinCatchmentArea
    update-catchmentArea
    set stock stock + sizeLevel * ((item 7 culturalVector) / 100) * ARIDinCatchmentArea

    ; determine the current and potential number of traders
    set currentNumberOfTraders get-current-number-of-traders
    set potentialNumberOfTraders get-potential-number-of-traders

    ; conditions favors the creation of new traders
    if (random-float 1 > currentNumberOfTraders / potentialNumberOfTraders )
    [
      ; create a new trader or activate an old one
      repeat 1
      [
        ifelse (any? traders with [not isActivated])
        [
          ask one-of traders with [not isActivated]
          [
            setup-trader thisSettlement
            move-to thisSettlement
          ]
        ]
        [
          hatch-traders 1
          [
            setup-trader thisSettlement
          ]
        ]
      ]
      set currentNumberOfTraders get-current-number-of-traders ; update currentNumberOfTraders
    ]

    ; add variation to the settlement traits (mutation)
    mutate-traits
  ]

end

to add-trade-effect [ aTrader ] ; ego = settlement

  ; cultural transmission trader to port
  let newCulturalVector []
  foreach culturalVector
  [ ?1 ->
    let otherSettlementTrait item (length newCulturalVector) [culturalSample] of aTrader
    let traitChange (otherSettlementTrait - ?1) * ((item 9 culturalVector) / 100)
    set newCulturalVector lput (?1 + traitChange) newCulturalVector
  ]
;  print (word "========== " self " ============")
;  print (word "old vector: " culturalVector ", new vector: " newCulturalVector)
  set culturalVector newCulturalVector

  set sizeLevel sizeLevel + [cargoValue] of aTrader

end

to mutate-traits

  let mutationVariationToApply (item 10 culturalVector) / 100
  ;print "========================================"
  ;print culturalVector
  ; #1, #2 and #3
  set culturalVector replace-item 0 culturalVector mutate-trait (item 0 culturalVector) 0 255 mutationVariationToApply
  set culturalVector replace-item 1 culturalVector mutate-trait (item 1 culturalVector) 0 255 mutationVariationToApply
  set culturalVector replace-item 2 culturalVector mutate-trait (item 2 culturalVector) 0 255 mutationVariationToApply

  ; #3 and #4 (relativePathCostInLand, relativePathCostInPort)
  set culturalVector replace-item 3 culturalVector mutate-trait (item 3 culturalVector) 0 100 mutationVariationToApply ; arbitrary maximum
  set culturalVector replace-item 4 culturalVector mutate-trait (item 4 culturalVector) 0 100 mutationVariationToApply ; arbitrary maximum

  ; #5, #6 and #6 (settlementSizeDecayRate, stockDecayRate, produtionRate)
  set culturalVector replace-item 5 culturalVector mutate-trait (item 5 culturalVector) 0 maxSettlementSizeDecayRate mutationVariationToApply
  set culturalVector replace-item 6 culturalVector mutate-trait (item 6 culturalVector) 0 maxStockDecayRate mutationVariationToApply
  set culturalVector replace-item 7 culturalVector mutate-trait (item 7 culturalVector) 0 maxProductionRate mutationVariationToApply

  ; #8, #9 and #10 (frequencyOverQuality, traitTransmissionRate, mutationVariation)
  set culturalVector replace-item 8 culturalVector mutate-trait (item 8 culturalVector) 0 1 mutationVariationToApply
  set culturalVector replace-item 9 culturalVector mutate-trait (item 9 culturalVector) 0 maxTraitTransmissionRate mutationVariationToApply
  set culturalVector replace-item 10 culturalVector mutate-trait (item 10 culturalVector) 0 maxMutationVariation mutationVariationToApply

  ;print culturalVector

end

to-report mutate-trait [ traitValue minValue maxValue mutationVar ]

  report (max (list minValue min (list maxValue (traitValue + (random-normal 0 mutationVar) * (maxValue - minValue)))))

end


to-report get-potential-number-of-traders ; ego = settlement

  report (
    1 +
    (sizeLevel - 1) * (item 8 culturalVector)
    )

end

to-report get-current-number-of-traders ; ego = settlement

  let thisSettlement self
  report count traders with [isActivated and base = thisSettlement ]

end

;;; weather variables and ARID ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-day-weather-from-input-data [ dayOfYear year ]

  ;;; find corresponding index to year-dayOfYear pair

  let yearAndDoyIndex position (word year "-" dayOfYear) weatherInputData_YEAR-DOY

  ;;; get values from weather input data

  set solarRadiation item yearAndDoyIndex weatherInputData_solarRadiation

  set T item yearAndDoyIndex weatherInputData_temperature

  set T_min item yearAndDoyIndex weatherInputData_minTemperature

  set T_max item yearAndDoyIndex weatherInputData_maxTemperature

  set RAIN item yearAndDoyIndex weatherInputData_precipitation

  if (dayOfYear = 1)
  [
    ;;; fill values of precipitation_yearSeries and precipitation_cumYearSeries, used here only for visualisation

    let yearLengthInDays item (currentYear - weatherInputData_firstYear) weatherInputData_yearLengthInDays
    let yearAndLastDoyIndex position (word year "-" yearLengthInDays) weatherInputData_YEAR-DOY

    set precipitation_yearSeries sublist weatherInputData_precipitation yearAndDoyIndex (yearAndLastDoyIndex + 1)

    let yearTotal sum precipitation_yearSeries
    set precipitation_cumYearSeries (list)
    let cumulativeSum 0
    foreach precipitation_yearSeries
    [
      i ->
      set cumulativeSum cumulativeSum + i
      set precipitation_cumYearSeries lput cumulativeSum precipitation_cumYearSeries
    ]
    set precipitation_cumYearSeries map [i -> i / yearTotal] precipitation_cumYearSeries
  ]

  ask patchesWithElevationData
  [
    set netSolarRadiation (1 - albedo) * solarRadiation
    set ETr get-ETr
  ]

end

to-report get-ETr

  ;;; useful references:
  ;;; Suleiman A A and Hoogenboom G 2007
  ;;; Comparison of Priestley-Taylor and FAO-56 Penman-Monteith for Daily Reference Evapotranspiration Estimation in Georgia
  ;;; J. Irrig. Drain. Eng. 133 175–82 Online: http://ascelibrary.org/doi/10.1061/%28ASCE%290733-9437%282007%29133%3A2%28175%29
  ;;; also: Jia et al. 2013 - doi:10.4172/2168-9768.1000112
  ;;; Allen, R. G., Pereira, L. A., Raes, D., and Smith, M. 1998.
  ;;; “Crop evapotranspiration.”FAO irrigation and  drainage paper 56, FAO, Rome.
  ;;; also: http://www.fao.org/3/X0490E/x0490e07.htm
  ;;; constants found in: http://www.fao.org/3/X0490E/x0490e07.htm
  ;;; see also r package: Evapotranspiration (consult source code)

  let windSpeed 2 ; as recommended by: http://www.fao.org/3/X0490E/x0490e07.htm#estimating%20missing%20climatic%20data

  ;;; estimation of saturated vapour pressure (e_s) and actual vapour pressure (e_a)
  let e_s (get-vapour-pressure T_max + get-vapour-pressure T_min) / 2
  let e_a get-vapour-pressure T_min
  ; ... in absence of dew point temperature, as recommended by
  ; http://www.fao.org/3/X0490E/x0490e07.htm#estimating%20missing%20climatic%20data
  ; however, possibly min temp > dew temp under arid conditions

  ;;; slope of  the  vapor  pressure-temperature  curve (kPa ºC−1)
  let DELTA 4098 * (get-vapour-pressure T) / (T + 237.3) ^ 2

  ;;; latent heat of vaporisation = 2.45 MJ.kg^-1
  let lambda 2.45

  ;;; specific heat at constant pressure, 1.013 10-3 [MJ kg-1 °C-1]
  let c_p 1.013 * 10 ^ -3
  ;;; ratio molecular weight of water vapour/dry air
  let epsilon 0.622
  ;;; atmospheric pressure (kPa)
  let P 101.3 * ((293 - 0.0065 * elevation) / 293) ^ 5.26
  ;;; psychometric constant (kPa ºC−1)
  let gamma c_p * P / (epsilon * lambda)

  ;;; Penman-Monteith equation from: fao.org/3/X0490E/x0490e0 ; and from: weap21.org/WebHelp/Mabia_Alg ETRef.htm

  ; 900 and 0.34 for the grass reference; 1600 and 0.38 for the alfalfa reference
  let C_n 900
  let C_d 0.34

  let ETr_temp (0.408 * DELTA * netSolarRadiation + gamma * (C_n / (T + 273)) * windSpeed * (e_s - e_a)) / (DELTA + gamma * (1 + C_d * windSpeed))

  report ETr_temp

end

to-report get-vapour-pressure [ temp ]

  report (0.6108 * exp(17.27 * temp / (temp + 237.3)))

end

to update-WAT

  ; Soil Water Balance model
  ; Using the approach of:
  ; 'Working with dynamic crop models: Methods, tools, and examples for agriculture and enviromnent'
  ;  Daniel Wallach, David Makowski, James W. Jones, François Brun (2006, 2014, 2019)
  ;  Model description in p. 24-28, R code example in p. 138-144.
  ;  see also https://github.com/cran/ZeBook/blob/master/R/watbal.model.r
  ; Some additional info about run off at: https://engineering.purdue.edu/mapserve/LTHIA7/documentation/scs.htm
  ; and at: https://en.wikipedia.org/wiki/Runoff_curve_number

  ; Maximum abstraction (mm; for run off)
  let S 25400 / CN - 254
  ; Initial Abstraction (mm; for run off)
  let IA 0.2 * S
  ; WATfc : Maximum Water content at field capacity (mm)
  let WATfc FC * z
  ; WATwp : Water content at wilting Point (mm)
  let WATwp WP * z

  ; Change in Water Before Drainage (Precipitation - Runoff)
  let RO 0
  if (RAIN > IA)
  [ set RO ((RAIN - 0.2 * S) ^ 2) / (RAIN + 0.8 * S) ]
  ; Calculating the amount of deep drainage
  let DR 0
  if (WAT + RAIN - RO > WATfc)
  [ set DR DC * (WAT + RAIN - RO - WATfc) ]

  ; Calculate rate of change of state variable WAT
  ; Compute maximum water uptake by plant roots on a day, RWUM
  let RWUM MUF * (WAT + RAIN - RO - DR - WATwp)
  ; Calculate the amount of water lost through transpiration (TR)
  let TR min (list RWUM ETr)

  let dWAT RAIN - RO - DR - TR
  set WAT WAT + dWAT

  set WATp WAT / z

  set ARID 0
  if (TR < ETr)
  [ set ARID 1 - TR / ETr ]

end

to modify-ARID

  set ARID ARID * ARID_modifier

end

to update-ARIDinCatchmentArea

  let patchesInCatchmentArea patches in-radius catchmentArea

  ifelse (count patchesInCatchmentArea = 1)
  [ set ARIDinCatchmentArea [ARID] of patch-here ]
  [ set ARIDinCatchmentArea mean [ARID] of patchesInCatchmentArea]

end

to update-catchmentArea

  set catchmentArea get-value-in-gradient sizeLevel catchmentSlope catchmentRadiusMaximum

end

to-report get-value-in-gradient [ input gradient maximum ]

  report e ^ ( - input / ((gradient / 100) * maximum) )

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; OUTPUT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-output

  let activatedTraders traders with [isActivated]

  set traderCount count activatedTraders

  set meanTraderCargoValue mean [cargoValue] of activatedTraders
  set minTraderCargoValue min [cargoValue] of activatedTraders
  set maxTraderCargoValue max [cargoValue] of activatedTraders

  set minSettlementSize min [sizeLevel] of settlements
  set maxSettlementSize max [sizeLevel] of settlements
  set mainHub max-one-of settlements [sizeLevel]

  set meanTotalPathCostOfActiveRoutes mean [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of activatedTraders
  set minTotalPathCostOfActiveRoutes min [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of activatedTraders
  set maxTotalPathCostOfActiveRoutes max [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of activatedTraders

  set meanRedTrait mean [item 0 culturalVector] of settlements
  set stdDevRedTrait standard-deviation [item 0 culturalVector] of settlements
  set modesRedTrait modes [ round (item 0 culturalVector) ] of settlements
  set meanGreenTrait mean [item 1 culturalVector] of settlements
  set stdDevGreenTrait standard-deviation [item 1 culturalVector] of settlements
  set modesGreenTrait modes [ round (item 1 culturalVector) ] of settlements
  set meanBlueTrait mean [item 2 culturalVector] of settlements
  set stdDevBlueTrait standard-deviation [item 2 culturalVector] of settlements
  set modesBlueTrait modes [ round (item 2 culturalVector) ] of settlements

  set meanLandTechTrait mean [item 3 culturalVector] of settlements
  set stdDevLandTechTrait standard-deviation [item 3 culturalVector] of settlements
  set modesLandTechTrait modes [ round (item 3 culturalVector) ] of settlements
  set meanPortTechTrait mean [item 4 culturalVector] of settlements
  set stdDevPortTechTrait standard-deviation [item 4 culturalVector] of settlements
  set modesPortTechTrait modes [ round (item 4 culturalVector) ] of settlements

  set meanSizeDecayTrait mean [item 5 culturalVector] of settlements
  set stdDevSizeDecayTrait standard-deviation [item 5 culturalVector] of settlements
  set modesSizeDecayTrait modes [ round (item 5 culturalVector) ] of settlements
  set meanStockDecayTrait mean [item 6 culturalVector] of settlements
  set stdDevStockDecayTrait standard-deviation [item 6 culturalVector] of settlements
  set modesStockDecayTrait modes [ round (item 6 culturalVector) ] of settlements
  set meanProductionTrait mean [item 7 culturalVector] of settlements
  set stdDevProductionTrait standard-deviation [item 7 culturalVector] of settlements
  set modesProductionTrait modes [ round (item 7 culturalVector) ] of settlements

  set meanFreqOverQualTrait mean [item 8 culturalVector] of settlements
  set stdDevFreqOverQualTrait standard-deviation [item 8 culturalVector] of settlements
  set modesFreqOverQualTrait modes [ round (item 8 culturalVector) ] of settlements
  set meanTransmissionTrait mean [item 9 culturalVector] of settlements
  set stdDevTransmissionTrait standard-deviation [item 9 culturalVector] of settlements
  set modesTransmissionTrait modes [ round (item 9 culturalVector) ] of settlements
  set meanMutationTrait mean [item 10 culturalVector] of settlements
  set stdDevMutationTrait standard-deviation [item 10 culturalVector] of settlements
  set modesMutationTrait modes [ round (item 10 culturalVector) ] of settlements

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DISPLAY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to refresh-view

  if (display-mode = "elevation")
  [
    ask patchesWithElevationData [ display-elevation ]
  ]

  if (display-mode = "albedo")
  [
    ask patchesWithElevationData [ display-albedo ]
  ]

  if (display-mode = "ETr")
  [
    let maxETr max [ETr] of patchesWithElevationData
    ask patchesWithElevationData [ display-ETr maxETr ]
  ]

  if (display-mode = "drainage coefficient (DC)")
  [
    ask patchesWithElevationData [ display-DC ]
  ]

  if (display-mode = "root zone depth (z)")
  [
    let maxZ max [z] of patchesWithElevationData
    ask patchesWithElevationData [ display-z maxZ ]
  ]

  if (display-mode = "runoff curve number (CN)")
  [
    let maxCN max [CN] of patchesWithElevationData
    ask patchesWithElevationData [ display-CN maxCN ]
  ]

  if (display-mode = "water content at field capacity (FC)")
  [
    let maxFC max [FC] of patchesWithElevationData
    ask patchesWithElevationData [ display-FC maxFC ]
  ]

  if (display-mode = "water holding Capacity (WHC)")
  [
    let maxWHC max [WHC] of patchesWithElevationData
    ask patchesWithElevationData [ display-WHC maxWHC ]
  ]

  if (display-mode = "soil water content (WATp)")
  [
    let maxWATp max [WATp] of patchesWithElevationData
    ask patchesWithElevationData [ display-WATp maxWATp ]
  ]

  if (display-mode = "ARID coefficient")
  [
    ask patchesWithElevationData [ display-arid ]
  ]

  display-flows

  paint-routes
  paint-active-routes

  ask settlements
  [
    set hidden? not showSettlements
    ; scale the size of settlements according to their dynamic free-scaled sizeLevel
    set size 1 + (sizeLevel / maxSettlementSize) * 9
    set color rgb (item 0 culturalVector) (item 1 culturalVector) (item 2 culturalVector)
  ]

  ask traders
  [
    ifelse (showTraders)
    [
      ifelse (isActivated)
      [ set hidden? false ]
      [ set hidden? true ]
    ]
    [ set hidden? true ]
  ]

end

to paint-routes

  ;;; define list of shades of red in NetLogo
  let redShades (list 11 12 13 14 15 16 17 18 19)
  ;;; NOTE: this is needed because rgb colors based on elevation are a list
  ;;; while NetLogo color are numbers

  ; resets route patches to the terrain color
  foreach routes
  [ ?1 ->
    let aRoute ?1

    foreach aRoute
    [ ??1 ->
      ask ??1 [ display-elevation ]
    ]
  ]

  ; paint route patches in shades of red depending on route frequency
  foreach routes
  [ ?1 ->
    let aRoute ?1

    foreach aRoute
    [ ??1 ->
      ask ??1
      [
        if (showRoutes)
        [
          ifelse (not member? pcolor redShades) ; if its the first route crossing the patch
          [
            set pcolor 11
          ]
          [
            set pcolor min (list (pcolor + 1) (19)) ; sets a maximum at 19 (the brightest)
          ]
        ]
      ]
    ]
  ]

end

to paint-active-routes

  ask traders
  [
    foreach route
    [ ?1 ->
      ask ?1
      [
        ifelse (showActiveRoutes)
        [
          set pcolor yellow
        ]
        [
          if (not showRoutes) ; if not displaying all routes
          [
            ; resets to the patch terrain color
            display-elevation
          ]
        ]
      ]
    ]
  ]

end

to display-elevation

  let elevationGradient 100 + (155 * (elevation / maxElevation))
  set pcolor rgb (elevationGradient - 100) elevationGradient 0

end

to display-albedo

  set pcolor 1 + 9 * albedo

end

to display-ETr [ maxETr ]

  ifelse (maxETr = 0)
  [ set pcolor 25 ]
  [ set pcolor 22 + 6 * (1 - ETr / maxETr) ]

end

to display-DC

  set pcolor 112 + 6 * (1 - DC)

end

to display-z [ maxZ ]

  set pcolor 42 + 8 * (1 - z / maxZ)

end

to display-CN [ maxCN ]

  set pcolor 72 + 6 * (1 - CN / maxCN)

end

to display-FC [ maxFC ]

  set pcolor 82 + 6 * (1 - FC / maxFC)

end

to display-WHC [ maxWHC ]

  set pcolor 92 + 6 * (1 - WHC / maxWHC)

end

to display-WATp [ maxWATp ]

  set pcolor 102 + 6 * (1 - WATp / maxWATp)

end

to display-ARID

  set pcolor 12 + 6 * ARID

end

to display-flows

  ask flowHolders
  [
    ask my-links
    [
      ifelse (show-flows) [ show-link ] [ hide-link ]
    ]
  ]

end

to plot-precipitation-table

  clear-plot

  let yearLengthInDays item (currentYear - weatherInputData_firstYear) weatherInputData_yearLengthInDays

  set-plot-x-range 0 (yearLengthInDays + 1)

  ;;; precipitation (mm/day) is summed by month
  foreach n-values yearLengthInDays [j -> j]
  [
    dayOfYearIndex ->
    plotxy (dayOfYearIndex + 1) (item dayOfYearIndex precipitation_yearSeries)
  ]
  plot-pen-up

end

to plot-cumPrecipitation-table

  clear-plot

  let yearLengthInDays item (currentYear - weatherInputData_firstYear) weatherInputData_yearLengthInDays

  set-plot-y-range -0.1 1.1
  set-plot-x-range 0 (yearLengthInDays + 1)

  ;;; precipitation (mm/day) is summed by month
  foreach n-values yearLengthInDays [j -> j]
  [
    dayOfYearIndex ->
    plotxy (dayOfYearIndex + 1) (item dayOfYearIndex precipitation_cumYearSeries)
  ]
  plot-pen-up

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LOAD DATA FROM TABLES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-weather-input-data-table

  ;;; this procedure loads the values of the weather data input table
  ;;; the table contains:
  ;;;   1. 13 lines of metadata, to be ignored
  ;;;   2. one line with the headers of the table
  ;;;   3. remaining rows containing row name and values

  let weatherTable csv:from-file "data/POWER_Point_Daily_19840101_20201231_035d0309N_024d8335E_LST.csv"

  ;;;==================================================================================================================
  ;;; mapping coordinates (row or columns) from headings (line 14 == index 13 -----------------------------------------
  ;;; NOTE: always correct raw mapping coordinates (start at 1) into list indexes (start at 0)
  let variableNames item (14 - 1) weatherTable

  let yearColumn position "YEAR" variableNames

  let solarRadiationColumn position "ALLSKY_SFC_SW_DWN" variableNames

  let precipitationColumn position "PRECTOTCORR" variableNames

  let temperatureColumn position "T2M" variableNames

  let temperatureMaxColumn position "T2M_MAX" variableNames

  let temperatureMinColumn position "T2M_MIN" variableNames

  ;;;==================================================================================================================
  ;;; extract data---------------------------------------------------------------------------------------

  ;;; read variables per year and day (list of lists, matrix: year-day x variables)
  let weatherData sublist weatherTable (15 - 1) (length weatherTable) ; select only those row corresponding to variable data, if there is anything else

  ;;; extract year-day of year pairs from the third and fourth columns
  set weatherInputData_YEARS map [row -> item yearColumn row ] weatherData

  ;;; NASA-POWER data uses year, month, day of month, instead of day of year,
  ;;; so we need to calculate day of year of each row ourselves
  set weatherInputData_DOY []
  set weatherInputData_yearLengthInDays []
  foreach (remove-duplicates weatherInputData_YEARS)
  [
    aYear ->
    let aDoy 1
    let lengthOfThisYear length (filter [i -> i = aYear] weatherInputData_YEARS)
    set weatherInputData_yearLengthInDays lput lengthOfThisYear weatherInputData_yearLengthInDays
    repeat lengthOfThisYear
    [
      set weatherInputData_DOY lput aDoy weatherInputData_DOY
      set aDoy aDoy + 1
    ]
  ]
  set weatherInputData_YEAR-DOY (map [[i j] -> (word i "-" j)] weatherInputData_YEARS weatherInputData_DOY)

  ;;; extract first and last year
  set weatherInputData_firstYear first weatherInputData_YEARS

  set weatherInputData_lastYear last weatherInputData_YEARS

  ;;; extract parameter values from the given column
  ;;; NOTE: read-from-string is required because the original file is formated in a way that NetLogo interprets values as strings.

  set weatherInputData_solarRadiation map [row -> item solarRadiationColumn row ] weatherData

  set weatherInputData_precipitation map [row -> item precipitationColumn row ] weatherData

  set weatherInputData_temperature map [row -> item temperatureColumn row ] weatherData

  set weatherInputData_maxTemperature map [row -> item temperatureMaxColumn row ] weatherData

  set weatherInputData_minTemperature map [row -> item temperatureMinColumn row ] weatherData

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Get and set routes (helper 'to-report' procedures) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report get-route [ settlement1 settlement2 ] ; accepts two settlements and returns a route

  ; get routes connecting settlement1
  let routesFromSettlement1 filter
  [ ?1 ->
    ([one-of settlements-here] of first ?1 = settlement1) or
    ([one-of settlements-here] of last ?1 = settlement1)
  ] routes

  ; get the route connecting settlement2 from the previous list
  let routeFromSettlement1ToSettlement2 filter
  [ ?1 ->
    ([one-of settlements-here] of first ?1 = settlement2) or
    ([one-of settlements-here] of last ?1 = settlement2)
  ] routesFromSettlement1

  report first routeFromSettlement1ToSettlement2

end

to-report get-routes-to-settlement [ aSettlement ] ; accepts a settlement and return a list of routes

  report filter
  [ ?1 ->
    ([one-of settlements-here] of first ?1 = aSettlement) or
    ([one-of settlements-here] of last ?1 = aSettlement)
  ] routes

end

to-report get-origin-and-destination [ aRoute ] ; accepts a route and returns a turtle-set with two settlements

  report (turtle-set ([ one-of settlements-here ] of first aRoute) ([one-of settlements-here ] of last aRoute))

end

to-report benefit-cost-of-route [ aRoute aTrader ] ; accepts a route andpan returns a number (the benefit/cost ratio of the route)

  let cost 0

  foreach aRoute ; for every patch in the given route
  [ ?1 ->
    set cost cost + get-path-cost ?1 aTrader
  ]

  let originAndDestination get-origin-and-destination aRoute
  let benefit 0
  ask originAndDestination [ set benefit benefit + sizeLevel ] ; the benefit is the sum of the sizeLevel of the two settlements

  report benefit / cost

end

to-report get-path-cost [ aPatch aTrader ]

  let pathCostOfPatch [pathCost] of aPatch
  ifelse ([any? settlements-here] of aPatch)
  [
    ; path cost in port apply
    set pathCostOfPatch pathCostOfPatch + [(item 4 culturalVector)] of [base] of aTrader
  ]
  [
    ; path cost in land apply
    set pathCostOfPatch pathCostOfPatch + [(item 3 culturalVector)] of [base] of aTrader
  ]
  report pathCostOfPatch

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; LOAD ROUTES DATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to import-routes-from-file

  ;;; get unique file name corresponding to the current setting
  let filePath (word "data/routes/routes_" simulation-period "_w=" world-width "_h=" world-height "_randomSeed=" randomSeed ".txt")

  ifelse (not file-exists? filePath)
  [ print (word "WARNING: could not find '" filePath "'") stop ] ;;; unfortunately the stop command doesn't stop the setup procedure
  [
    file-open filePath

    set routes []

    while [not file-at-end?]
    [
      let lineString file-read-line
      set lineString remove-item 0 lineString
      set lineString remove-item (length lineString - 1) lineString
      set lineString (word "(list " lineString " )")

      set routes lput (run-result lineString) routes
    ]
  ]

  file-close

end
@#$#@#$#@
GRAPHICS-WINDOW
379
10
1125
484
-1
-1
3.0
1
10
1
1
1
0
1
1
1
0
245
0
154
0
0
1
ticks
30.0

BUTTON
14
11
69
44
NIL
setup
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
189
10
244
43
NIL
go
T
1
T
OBSERVER
NIL
4
NIL
NIL
1

INPUTBOX
5
54
105
114
randomSeed
0.0
1
0
Number

BUTTON
71
11
126
44
NIL
go
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

PLOT
1206
185
1841
369
Temperature
days
ºC
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot T"
"min" 1.0 0 -13345367 true "" "plot T_min"
"max" 1.0 0 -2674135 true "" "plot T_max"

PLOT
1207
372
1799
514
Solar radiation
days
MJ/m2
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot solarRadiation"

MONITOR
271
10
350
55
NIL
currentYear
0
1
11

MONITOR
259
61
373
106
NIL
currentDayOfYear
0
1
11

CHOOSER
14
204
260
249
display-mode
display-mode
"elevation" "albedo" "ETr" "drainage coefficient (DC)" "root zone depth (z)" "runoff curve number (CN)" "water content at field capacity (FC)" "water holding Capacity (WHC)" "soil water content (WATp)" "ARID coefficient"
0

BUTTON
269
212
343
245
refresh view
refresh-view
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
128
10
188
43
+ year
repeat 365 [ go ]
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

PLOT
1203
514
1864
672
precipitation
days
ppm
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"RAIN" 1.0 1 -16777216 true "" "plot RAIN"
"mean ETr" 1.0 0 -2674135 true "" "plot mean[ETr] of patches"

PLOT
1492
674
1749
794
cumulative year precipitation
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range -0.1 1.1\nlet yearLengthInDays item (currentYear - weatherInputData_firstYear) weatherInputData_yearLengthInDays\nset-plot-x-range 0 (yearLengthInDays + 1)" ""
PENS
"default" 1.0 0 -16777216 true "" "if (currentDayOfYear = 1) [ plot-cumPrecipitation-table ]"

PLOT
1259
674
1492
794
year preciptation
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"let yearLengthInDays item (currentYear - weatherInputData_firstYear) weatherInputData_yearLengthInDays\nset-plot-x-range 0 (yearLengthInDays + 1)" ""
PENS
"default" 1.0 1 -16777216 true "" "if (currentDayOfYear = 1) [ plot-precipitation-table ]"

MONITOR
1751
709
1824
754
year total
sum precipitation_yearSeries
2
1
11

PLOT
1206
10
1869
185
Soil water content & ARID
days
NIL
0.0
10.0
0.0
10.0
true
true
"set-plot-y-range -0.1 1.1" ""
PENS
"mean ARID" 1.0 0 -16777216 true "" "plot mean [ARID] of patchesWithElevationData"
"mean WTp" 1.0 0 -13345367 true "" "plot mean [WATp] of patchesWithElevationData"

SLIDER
26
648
257
681
drainage-coefficient_min
drainage-coefficient_min
0
drainage-coefficient_max
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
27
683
257
716
root-zone-depth_min
root-zone-depth_min
0
root-zone-depth_max
200.0
1
1
mm
HORIZONTAL

SLIDER
27
715
257
748
runoff-curve_min
runoff-curve_min
0
runoff-curve_max
5.0
1
1
NIL
HORIZONTAL

MONITOR
491
1016
584
1053
WHC [min, max]
(list (precision WHC_min 2) (precision WHC_max 2))
2
1
9

MONITOR
459
647
542
684
DC [min, max]
(list (precision DC_min 2) (precision DC_max 2))
2
1
9

MONITOR
459
678
543
715
z [min, max]
(list (precision z_min 2) (precision z_max 2))
2
1
9

MONITOR
458
713
543
750
CN [min, max]
(list (precision CN_min 2) (precision CN_max 2))
2
1
9

BUTTON
379
493
533
526
NIL
parameters-to-default
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
26
581
255
614
par_albedo_min
par_albedo_min
0
par_albedo_max
0.2
0.01
1
NIL
HORIZONTAL

MONITOR
469
981
559
1018
albedo [min, max]
(list (precision albedo_min 2) (precision albedo_max 2))
2
1
9

SLIDER
255
581
458
614
par_albedo_max
par_albedo_max
par_albedo_min
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
254
614
482
647
water-holding-capacity_max
water-holding-capacity_max
water-holding-capacity_min
0.2
0.5
1
1
cm3/cm3
HORIZONTAL

SLIDER
254
647
459
680
drainage-coefficient_max
drainage-coefficient_max
drainage-coefficient_min
1
2000.0
1
1
NIL
HORIZONTAL

SLIDER
255
682
461
715
root-zone-depth_max
root-zone-depth_max
root-zone-depth_min
2000
2000.0
1
1
mm
HORIZONTAL

SLIDER
256
715
458
748
runoff-curve_max
runoff-curve_max
runoff-curve_min
100
80.0
1
1
NIL
HORIZONTAL

SWITCH
7
123
113
156
show-flows
show-flows
0
1
-1000

SLIDER
25
615
256
648
water-holding-capacity_min
water-holding-capacity_min
0.01
water-holding-capacity_max
0.05
0.01
1
cm3/cm3
HORIZONTAL

SLIDER
8
537
269
570
ARID-decrease-per-flow-accumulation
ARID-decrease-per-flow-accumulation
0
1
0.5
0.01
1
NIL
HORIZONTAL

CHOOSER
116
62
254
107
simulation-period
simulation-period
"EMIII-MMIA" "MMIB"
0

SWITCH
115
123
224
156
showRoutes
showRoutes
0
1
-1000

SLIDER
40
335
315
368
maxSettlementSizeDecayRate
maxSettlementSizeDecayRate
0
25
20.0
0.01
1
% of sizeLevel
HORIZONTAL

SWITCH
226
123
366
156
showActiveRoutes
showActiveRoutes
0
1
-1000

SLIDER
35
440
315
473
maxTraitTransmissionRate
maxTraitTransmissionRate
0
25
20.0
0.01
1
% of trait difference
HORIZONTAL

SLIDER
40
259
316
292
relativePathCostInPort
relativePathCostInPort
1
100
10.0
0.01
1
X path cost in water
HORIZONTAL

SLIDER
40
368
315
401
maxStockDecayRate
maxStockDecayRate
0
25
20.0
0.01
1
% of stock
HORIZONTAL

SLIDER
40
401
315
434
maxProductionRate
maxProductionRate
0
25
15.0
0.01
1
% of sizeLevel
HORIZONTAL

SLIDER
40
300
178
333
landTechVariation
landTechVariation
0
20
5.0
0.01
1
NIL
HORIZONTAL

SLIDER
178
300
315
333
portTechVariation
portTechVariation
0
20
5.0
0.01
1
NIL
HORIZONTAL

SLIDER
35
475
315
508
maxMutationVariation
maxMutationVariation
0
5
1.0
0.01
1
% of trait range
HORIZONTAL

PLOT
620
506
865
626
Traders
ticks
count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot traderCount"

PLOT
620
631
865
751
Settlement size distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"carefully [set-plot-x-range -0.1 ((max [sizeLevel] of settlements) + 0.1)] [ set-plot-x-range 0 1 ]\nset-histogram-num-bars 20" "carefully [set-plot-x-range -0.1 ((max [sizeLevel] of settlements) + 0.1)] [ set-plot-x-range 0 1 ]\nset-histogram-num-bars 20"
PENS
"default" 1.0 1 -16777216 true "histogram [sizeLevel] of settlements" "histogram [sizeLevel] of settlements"

PLOT
865
631
1160
751
Main hub settlement
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "carefully [ set-plot-pen-color approximate-rgb (item 0 ([color] of mainHub)) (item 1 ([color] of mainHub)) (item 2 ([color] of mainHub))] []\ncarefully [ plot [who] of mainHub] [ plot 0 ]"

MONITOR
775
751
860
788
max. (sizeLevel)
maxSettlementSize
2
1
9

MONITOR
639
751
723
788
min. (sizeLevel)
minSettlementSize
2
1
9

MONITOR
875
751
1145
788
hub settlements (>80% of max. sizeLevel)
(word (count settlements with [sizeLevel > 0.8 * max [sizeLevel] of settlements]) \" \" (sort [who] of settlements with [sizeLevel > 0.8 * [sizeLevel] of mainHub]))
2
1
9

PLOT
314
810
582
930
Neutral traits
variants
frequency
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range -1 256" "set-plot-x-range -1 256"
PENS
"trait 1#" 1.0 1 -2674135 true "set-histogram-num-bars 33\nhistogram [item 0 culturalVector] of settlements" "histogram [item 0 culturalVector] of settlements"
"trait 2#" 1.0 1 -10899396 true "set-histogram-num-bars 25\nhistogram [item 1 culturalVector] of settlements" "histogram [item 1 culturalVector] of settlements"
"trait 3#" 1.0 1 -13345367 true "set-histogram-num-bars 20\nhistogram [item 1 culturalVector] of settlements" "histogram [item 2 culturalVector] of settlements"

TEXTBOX
323
934
348
969
#1
12
0.0
1

MONITOR
348
932
408
969
mean
meanRedTrait
2
1
9

MONITOR
408
932
467
969
std. dev
stdDevRedTrait
2
1
9

MONITOR
467
932
571
969
modes
(word (length modesRedTrait) \" \" modesRedTrait)
2
1
9

TEXTBOX
323
971
348
1006
#2
12
0.0
1

MONITOR
348
969
408
1006
mean
meanGreenTrait
2
1
9

MONITOR
408
969
467
1006
std. dev.
stdDevGreenTrait
2
1
9

MONITOR
467
969
571
1006
modes
(word (length modesGreenTrait) \" \" modesGreenTrait)
2
1
9

TEXTBOX
323
1008
348
1043
#3
12
0.0
1

MONITOR
348
1006
408
1043
mean
meanBlueTrait
2
1
9

MONITOR
408
1006
467
1043
std. dev.
stdDevBlueTrait
2
1
9

MONITOR
467
1006
571
1043
modes
(word (length modesBlueTrait) \" \" modesBlueTrait)
2
1
9

PLOT
582
810
850
930
Trader technology (movement cost)
variant
frequency
0.0
10.0
0.0
10.0
true
true
"" "carefully [ set-plot-x-range floor min [min (list (item 3 culturalVector) (item 4 culturalVector))] of settlements - 1  ceiling max [max (list (item 3 culturalVector) (item 4 culturalVector))] of settlements + 1 ] []"
PENS
"land" 1.0 1 -955883 true "set-histogram-num-bars 25" "set-histogram-num-bars 25\nhistogram [item 3 culturalVector] of settlements"
"port" 1.0 1 -13403783 true "set-histogram-num-bars 20" "set-histogram-num-bars 20\nhistogram [relativePathCostInPort + item 4 culturalVector] of settlements"

TEXTBOX
593
934
617
967
Land
10
0.0
1

MONITOR
617
930
677
967
mean
meanLandTechTrait
2
1
9

MONITOR
677
930
737
967
std. dev
stdDevLandTechTrait
2
1
9

MONITOR
737
930
841
967
modes
(word (length modesLandTechTrait) \" \" modesLandTechTrait)
2
1
9

TEXTBOX
593
971
617
1004
Port
10
0.0
1

MONITOR
617
967
677
1004
mean
relativePathCostInPort + meanPortTechTrait
2
1
9

MONITOR
677
967
737
1004
std. dev.
stdDevPortTechTrait
2
1
9

MONITOR
737
967
841
1004
modes
(word (length modesPortTechTrait) \" \" modesPortTechTrait)
2
1
9

PLOT
850
810
1118
930
Settlement economy traits
variant
frequency
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range -0.1 1.1" "set-plot-x-range -0.1 1.1"
PENS
"size decay" 1.0 1 -4079321 true "set-histogram-num-bars 33" "histogram [(item 5 culturalVector) / maxSettlementSizeDecayRate] of settlements"
"stock decay" 1.0 1 -15302303 true "set-histogram-num-bars 25" "histogram [(item 6 culturalVector) / maxStockDecayRate] of settlements"
"production" 1.0 1 -5825686 true "set-histogram-num-bars 20" "histogram [(item 7 culturalVector) / maxProductionRate] of settlements"

TEXTBOX
859
932
885
967
size decay
9
0.0
1

MONITOR
885
930
945
967
mean
meanSizeDecayTrait
2
1
9

MONITOR
945
930
1005
967
std. dev
stdDevSizeDecayTrait
2
1
9

MONITOR
1005
930
1109
967
modes
(word (length modesSizeDecayTrait) \" \" modesSizeDecayTrait)
2
1
9

TEXTBOX
859
969
885
1004
stock decay
9
0.0
1

MONITOR
885
967
945
1004
mean
meanStockDecayTrait
2
1
9

MONITOR
945
967
1005
1004
std. dev.
stdDevStockDecayTrait
2
1
9

MONITOR
1005
967
1109
1004
modes
(word (length modesStockDecayTrait) \" \" modesStockDecayTrait)
2
1
9

TEXTBOX
859
1006
885
1041
prod.
9
0.0
1

MONITOR
885
1004
945
1041
mean
meanProductionTrait
2
1
9

MONITOR
945
1004
1005
1041
std. dev.
stdDevProductionTrait
2
1
9

MONITOR
1005
1004
1109
1041
modes
(word (length modesProductionTrait) \" \" modesProductionTrait)
2
1
9

PLOT
1118
810
1386
930
Attitude traits
variant
frequency
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range -0.1 1.1" "set-plot-x-range -0.1 1.1"
PENS
"freq./qual." 1.0 1 -13840069 true "set-histogram-num-bars 33" "histogram [item 8 culturalVector] of settlements"
"transmission" 1.0 1 -7858858 true "set-histogram-num-bars 25" "set-histogram-num-bars 25\nhistogram [(item 9 culturalVector) / maxTraitTransmissionRate] of settlements"
"mutation" 1.0 1 -13791810 true "set-histogram-num-bars 20" "set-histogram-num-bars 20\nhistogram [(item 10 culturalVector) / maxMutationVariation] of settlements"

TEXTBOX
1121
932
1151
963
freq./ qual.
9
0.0
1

MONITOR
1151
930
1211
967
mean
meanFreqOverQualTrait
2
1
9

MONITOR
1211
930
1271
967
st. dev
stdDevFreqOverQualTrait
2
1
9

MONITOR
1271
930
1386
967
modes
(word (length modesFreqOverQualTrait) \" \" modesFreqOverQualTrait)
2
1
9

TEXTBOX
1121
969
1151
1000
trans.
9
0.0
1

MONITOR
1151
967
1211
1004
mean
meanTransmissionTrait
2
1
9

MONITOR
1211
967
1271
1004
st. dev.
stdDevTransmissionTrait
2
1
9

MONITOR
1271
967
1386
1004
modes
(word (length modesTransmissionTrait) \" \" modesTransmissionTrait)
2
1
9

TEXTBOX
1121
1006
1151
1041
mut.
9
0.0
1

MONITOR
1151
1004
1211
1041
mean
meanMutationTrait
2
1
9

MONITOR
1211
1004
1271
1041
st. dev.
stdDevMutationTrait
2
1
9

MONITOR
1271
1004
1386
1041
modes
(word (length modesMutationTrait) \" \" modesMutationTrait)
2
1
9

MONITOR
97
890
262
927
mean total path cost of active routes
meanTotalPathCostOfActiveRoutes
2
1
9

PLOT
27
770
282
890
Total path cost of active routes (mean)
ticks
pathCost
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "carefully [ plot mean [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of traders with [isActivated]] [ ]"

PLOT
20
927
305
1047
Total path cost of active routes (distribution)
total path cost
frequency
0.0
10.0
0.0
10.0
true
false
"carefully [set-plot-x-range -0.1 ((max [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of traders with [isActivated]) + 0.1)] [ set-plot-x-range 0 1 ]\nset-histogram-num-bars 30" "carefully [set-plot-x-range -0.1 ((max [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of traders with [isActivated]) + 0.1)] [ set-plot-x-range 0 1 ]\nset-histogram-num-bars 30"
PENS
"default" 1.0 1 -16777216 true "" "histogram [sum (map [ ?1 -> [pathCost] of ?1 ] route)] of traders with [isActivated]"

MONITOR
408
1044
468
1081
interval
\"[ 0 - 255 )\"
17
1
9

MONITOR
658
1004
728
1041
interval (land)
(word \"[ \" (floor min [item 3 culturalVector] of settlements) \" - \" (ceiling max [item 3 culturalVector] of settlements) \" ]\")
17
1
9

MONITOR
1038
1044
1128
1081
interval (production)
(word \"[ 0 - \" maxProductionRate \" ]\")
17
1
9

MONITOR
853
1044
943
1081
interval (size decay)
(word \"[ 0 - \" maxSettlementSizeDecayRate \" ]\")
17
1
9

MONITOR
943
1044
1038
1081
interval (stock decay)
(word \"[ 0 - \" maxStockDecayRate \" ]\")
17
1
9

MONITOR
1148
1044
1218
1081
interval (trans.)
(word \"[ 0 - \" maxTraitTransmissionRate \" ]\")
17
1
9

MONITOR
1218
1044
1288
1081
interval (mut.)
(word \"[ 0 - \" maxMutationVariation \" ]\")
17
1
9

MONITOR
728
1004
806
1041
interval (port)
(word \"[ \" floor (relativePathCostInPort + min [item 4 culturalVector] of settlements) \" - \" ceiling (relativePathCostInPort + max [item 4 culturalVector] of settlements) \" ]\")
17
1
9

PLOT
865
506
1160
626
Cargo value
ticks
value
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot meanTraderCargoValue"
"min" 1.0 0 -13791810 true "" "plot minTraderCargoValue"
"max" 1.0 0 -2674135 true "" "plot maxTraderCargoValue"

SWITCH
34
161
184
194
showSettlements
showSettlements
0
1
-1000

SWITCH
208
163
335
196
showTraders
showTraders
0
1
-1000

SLIDER
271
538
390
571
catchmentSlope
catchmentSlope
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
389
538
622
571
catchmentRadiusMaximum
catchmentRadiusMaximum
0
20
10.0
1
1
patches away
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

line half 1
true
0
Line -7500403 true 150 0 150 300
Rectangle -7500403 true true 135 0 165 150

line half 2
true
0
Line -7500403 true 150 0 150 300
Rectangle -7500403 true true 120 0 180 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2190"/>
    <metric>T</metric>
    <metric>T_max</metric>
    <metric>T_min</metric>
    <metric>RAIN</metric>
    <metric>solarRadiation</metric>
    <metric>ETr</metric>
    <metric>mean [WATp] of patches</metric>
    <metric>mean [ARID] of patches</metric>
    <metric>mean [biomass] of patches with [position crop typesOfCrops = 0]</metric>
    <metric>mean [biomass] of patches with [position crop typesOfCrops = 1]</metric>
    <metric>mean [yield] of patches with [position crop typesOfCrops = 0]</metric>
    <metric>mean [yield] of patches with [position crop typesOfCrops = 1]</metric>
    <enumeratedValueSet variable="precipitation_daily-cum_rate2_yearly-mean">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CO2-mean">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar_annual-min">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_rate2_yearly-sd">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CO2-daily-fluctuation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_yearly-sd">
      <value value="130"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar_annual-max">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_plateau-value_yearly-sd">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_n-sample">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection1_yearly-sd">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CO2-annual-deviation">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_max-sample-size">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection2_yearly-sd">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection2_yearly-mean">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_mean-daily-fluctuation">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_annual-min-at-2m">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar_mean-daily-fluctuation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_daily-lower-deviation">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_annual-max-at-2m">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_daily-upper-deviation">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-simulation-in-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_yearly-mean">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection1_yearly-mean">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_rate1_yearly-mean">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;crops&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_plateau-value_yearly-mean">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_rate1_yearly-sd">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="type-of-experiment">
      <value value="&quot;user-defined&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
