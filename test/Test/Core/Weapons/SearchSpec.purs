module Test.Core.Weapons.SearchSpec (spec) where

import Core.Database.VLatest
import Prelude
import Test.Spec

import Core.Weapons.Search (AssignmentResult)
import Core.Weapons.Search as Search
import Data.Array as Arr
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Nullable (null)
import Data.Nullable as Null
import Data.Set as Set
import Data.String.NonEmpty (NonEmptyString)
import Data.String.NonEmpty as NES
import Data.Tuple (Tuple(..))
import Test.Utils (nes, shouldEqualPretty)
import Test.Utils as T
import Utils (unsafeFromJust)

spec :: Spec Unit
spec =
  describe "search" do
    combinationsSpec
    assignWeaponsToCharactersSpec
    searchExamplesSpec

combinationsSpec :: Spec Unit
combinationsSpec = do
  describe "combinations" do
    let
      weapon11 = mkWeapon (nes @"11") (nes @" ")
      weapon12 = mkWeapon (nes @"12") (nes @" ")
      weapon13 = mkWeapon (nes @"13") (nes @" ")
      weapon21 = mkWeapon (nes @"21") (nes @" ")
      weapon22 = mkWeapon (nes @"22") (nes @" ")
      weapon31 = mkWeapon (nes @"31") (nes @" ")

      potencies11 = Just { base: Low, max: Low }
      potencies12 = Just { base: Low, max: Mid }
      potencies13 = Just { base: Low, max: High }
      potencies21 = Just { base: Mid, max: Mid }
      potencies22 = Just { base: Mid, max: High }
      potencies31 = Just { base: High, max: High }

    it "finds all possible combinations" do
      let
        combs = Search.combinations
          [ { filter: filter1
            , matchingWeapons:
                [ { weapon: weapon11, potenciesAtOb10: potencies11 }
                , { weapon: weapon12, potenciesAtOb10: potencies12 }
                , { weapon: weapon13, potenciesAtOb10: potencies13 }
                ]
            }
          , { filter: filter2
            , matchingWeapons:
                [ { weapon: weapon21, potenciesAtOb10: potencies21 }
                , { weapon: weapon22, potenciesAtOb10: potencies22 }
                ]
            }
          , { filter: filter3
            , matchingWeapons:
                [ { weapon: weapon31, potenciesAtOb10: potencies31 }
                ]
            }
          ]

      combs `shouldEqualPretty`
        [ [ { filter: filter1, weapon: weapon11, potenciesAtOb10: potencies11 }
          , { filter: filter2, weapon: weapon21, potenciesAtOb10: potencies21 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon11, potenciesAtOb10: potencies11 }
          , { filter: filter2, weapon: weapon22, potenciesAtOb10: potencies22 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon12, potenciesAtOb10: potencies12 }
          , { filter: filter2, weapon: weapon21, potenciesAtOb10: potencies21 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon12, potenciesAtOb10: potencies12 }
          , { filter: filter2, weapon: weapon22, potenciesAtOb10: potencies22 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon13, potenciesAtOb10: potencies13 }
          , { filter: filter2, weapon: weapon21, potenciesAtOb10: potencies21 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon13, potenciesAtOb10: potencies13 }
          , { filter: filter2, weapon: weapon22, potenciesAtOb10: potencies22 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        ]

    it "returns no combinations when a match is not found for a required effect" do
      let
        combs = Search.combinations
          [ { filter: filter1
            , matchingWeapons:
                [ { weapon: weapon11, potenciesAtOb10: potencies11 }
                , { weapon: weapon12, potenciesAtOb10: potencies12 }
                ]
            }
          , { filter: filter2
            , matchingWeapons:
                [ { weapon: weapon21, potenciesAtOb10: potencies21 }
                , { weapon: weapon22, potenciesAtOb10: potencies22 }
                ]
            }
          , { filter: filter3
            , matchingWeapons:
                [
                ]
            }
          ]
      combs `shouldEqualPretty` []

    it "discards ignored weapons" do
      let
        combs = Search.combinations
          [ { filter: filter1
            , matchingWeapons:
                [ { weapon: weapon11 { ignored = true }, potenciesAtOb10: potencies11 }
                , { weapon: weapon12, potenciesAtOb10: potencies12 }
                , { weapon: weapon13, potenciesAtOb10: potencies13 }
                ]
            }
          , { filter: filter2
            , matchingWeapons:
                [ { weapon: weapon21, potenciesAtOb10: potencies21 }
                , { weapon: weapon22, potenciesAtOb10: potencies22 }
                ]
            }
          , { filter: filter3
            , matchingWeapons:
                [ { weapon: weapon31, potenciesAtOb10: potencies31 }
                ]
            }
          ]

      combs `shouldEqualPretty`
        [ [ { filter: filter1, weapon: weapon12, potenciesAtOb10: potencies12 }
          , { filter: filter2, weapon: weapon21, potenciesAtOb10: potencies21 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon12, potenciesAtOb10: potencies12 }
          , { filter: filter2, weapon: weapon22, potenciesAtOb10: potencies22 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon13, potenciesAtOb10: potencies13 }
          , { filter: filter2, weapon: weapon21, potenciesAtOb10: potencies21 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        , [ { filter: filter1, weapon: weapon13, potenciesAtOb10: potencies13 }
          , { filter: filter2, weapon: weapon22, potenciesAtOb10: potencies22 }
          , { filter: filter3, weapon: weapon31, potenciesAtOb10: potencies31 }
          ]
        ]

    it "stack safety" do
      let
        filters = Arr.range 0 5 <#> \i -> do
          { filter:
              { effectType: Arr.index allFilterEffectTypes i `unsafeFromJust` "aaa"
              , range: FilterAll
              }
          , matchingWeapons: Arr.range 0 10 <#> \j -> do
              let
                weaponName = nes @"Weapon - "
                  # flip NES.appendString (show i)
                  # flip NES.appendString " - "
                  # flip NES.appendString (show j)
              { weapon: mkWeapon weaponName (nes @"Glenn")
              , potenciesAtOb10: Nothing
              }
          }
        _result = Search.combinations filters
      pure unit

assignWeaponsToCharactersSpec :: Spec Unit
assignWeaponsToCharactersSpec = do
  describe "assignWeaponsToCharacters" do
    let tifaWeapon1 = mkWeapon (nes @"Tifa 1") (nes @"Tifa")
    let tifaWeapon2 = mkWeapon (nes @"Tifa 2") (nes @"Tifa")
    let tifaWeapon3 = mkWeapon (nes @"Tifa 3") (nes @"Tifa")

    let vincentWeapon1 = mkWeapon (nes @"Vincent 1") (nes @"Vincent")
    let vincentWeapon2 = mkWeapon (nes @"Vincent 2") (nes @"Vincent")

    let redWeapon1 = mkWeapon (nes @"Red XIII 1") (nes @"Red XIII")

    let potencies1 = Just { base: Low, max: Low }
    let potencies2 = Just { base: Low, max: Mid }
    let potencies3 = Just { base: Low, max: High }
    let potencies4 = Just { base: Mid, max: Mid }
    let potencies5 = Just { base: Mid, max: High }

    it "assigns weapons correctly" do
      let
        combination =
          [ { filter: filter1, weapon: tifaWeapon1, potenciesAtOb10: potencies1 }
          , { filter: filter2, weapon: tifaWeapon2, potenciesAtOb10: potencies2 }
          , { filter: filter3, weapon: vincentWeapon1, potenciesAtOb10: potencies3 }
          , { filter: filter4, weapon: vincentWeapon2, potenciesAtOb10: potencies4 }
          ]

      Search.assignWeaponsToCharacters 3 combination `shouldEqualPretty`
        Just
          { characters:
              ( Map.fromFoldable
                  [ Tuple "Tifa"
                      { name: CharacterName $ nes @"Tifa"
                      , mainHand: Just
                          { weapon: tifaWeapon1
                          , matchedFilters: [ { filter: filter1, potenciesAtOb10: potencies1 } ]
                          }
                      , offHand: Just
                          { weapon: tifaWeapon2
                          , matchedFilters: [ { filter: filter2, potenciesAtOb10: potencies2 } ]
                          }
                      }
                  , Tuple "Vincent"
                      { name: CharacterName $ nes @"Vincent"
                      , mainHand: Just
                          { weapon: vincentWeapon1
                          , matchedFilters: [ { filter: filter3, potenciesAtOb10: potencies3 } ]
                          }
                      , offHand: Just
                          { weapon: vincentWeapon2
                          , matchedFilters: [ { filter: filter4, potenciesAtOb10: potencies4 } ]
                          }
                      }
                  ]
              )
          }

    it "handles a weapon matching on 2 or more effects" do
      let
        combination =
          [ { filter: filter1, weapon: tifaWeapon1, potenciesAtOb10: potencies1 }
          , { filter: filter2, weapon: tifaWeapon1, potenciesAtOb10: potencies2 }
          , { filter: filter3, weapon: tifaWeapon2, potenciesAtOb10: potencies3 }
          , { filter: filter4, weapon: tifaWeapon2, potenciesAtOb10: potencies4 }
          , { filter: filter5, weapon: vincentWeapon1, potenciesAtOb10: potencies5 }
          ]

      Search.assignWeaponsToCharacters 3 combination `shouldEqualPretty`
        Just
          { characters:
              ( Map.fromFoldable
                  [ Tuple "Tifa"
                      { name: CharacterName $ nes @"Tifa"
                      , mainHand: Just
                          { weapon: tifaWeapon1
                          , matchedFilters:
                              [ { filter: filter2, potenciesAtOb10: potencies2 }
                              , { filter: filter1, potenciesAtOb10: potencies1 }
                              ]
                          }
                      , offHand: Just
                          { weapon: tifaWeapon2
                          , matchedFilters:
                              [ { filter: filter4, potenciesAtOb10: potencies4 }
                              , { filter: filter3, potenciesAtOb10: potencies3 }
                              ]
                          }
                      }
                  , Tuple "Vincent"
                      { name: CharacterName $ nes @"Vincent"
                      , mainHand: Just
                          { weapon: vincentWeapon1
                          , matchedFilters:
                              [ { filter: filter5, potenciesAtOb10: potencies5 }
                              ]
                          }
                      , offHand: Nothing
                      }
                  ]
              )
          }

    it "fails if more than 2 weapons were selected for the same character" do
      let
        combination =
          [ { filter: filter1, weapon: tifaWeapon1, potenciesAtOb10: potencies1 }
          , { filter: filter2, weapon: tifaWeapon2, potenciesAtOb10: potencies2 }
          , { filter: filter3, weapon: tifaWeapon3, potenciesAtOb10: potencies3 }
          ]

      Null.toNullable (Search.assignWeaponsToCharacters 3 combination) `shouldEqualPretty` null

    it "fails if more than 2 characters were selected" do
      let
        combination =
          [ { filter: filter1, weapon: tifaWeapon1, potenciesAtOb10: potencies1 }
          , { filter: filter2, weapon: vincentWeapon1, potenciesAtOb10: potencies2 }
          , { filter: filter3, weapon: redWeapon1, potenciesAtOb10: potencies3 }
          ]

      Null.toNullable (Search.assignWeaponsToCharacters 2 combination) `shouldEqualPretty` null

searchExamplesSpec :: Spec Unit
searchExamplesSpec = do
  describe "search examples" do
    it "example 1" do
      armory <- T.loadTestDb
      let
        filters =
          [ { effectType: FilterHeal, range: FilterAll }
          , { effectType: FilterPatkUp, range: FilterAll }
          , { effectType: FilterPatkDown, range: FilterAll }
          ]
        maxCharacterCount = 1
        mustHaveChars = Set.empty
        results = Search.search2 maxCharacterCount filters armory
          # Search.filterMustHaveChars mustHaveChars
          # Search.filterDuplicates
      T.goldenTest "snaps/search-example-1.snap" $ teamSummary <$> results
    it "example 2" do
      armory <- T.loadTestDb
      let
        filters =
          [ { effectType: FilterHeal, range: FilterAll }
          , { effectType: FilterMatkUp, range: FilterAll }
          , { effectType: FilterMdefDown, range: FilterAll }
          , { effectType: FilterFireResistDown, range: FilterSingleTargetOrAll }
          , { effectType: FilterMdefUp, range: FilterAll }
          ]
        maxCharacterCount = 2
        mustHaveChars = Set.empty
        results = Search.search2 maxCharacterCount filters armory
          # Search.filterMustHaveChars mustHaveChars
          # Search.filterDuplicates
      T.goldenTest "snaps/search-example-2.snap" $ teamSummary <$> results
    it "example 3" do
      armory <- T.loadTestDb
      let
        filters =
          [ { effectType: FilterPdefDown, range: FilterSingleTargetOrAll }
          , { effectType: FilterPatkUp, range: FilterSingleTargetOrAll }
          , { effectType: FilterHeal, range: FilterAll }
          , { effectType: FilterWaterResistDown, range: FilterSingleTargetOrAll }
          , { effectType: FilterPatkDown, range: FilterSingleTargetOrAll }
          , { effectType: FilterMatkDown, range: FilterSingleTargetOrAll }
          ]
        maxCharacterCount = 2
        mustHaveChars = Set.empty
        results = Search.search2 maxCharacterCount filters armory
          # Search.filterMustHaveChars mustHaveChars
          # Search.filterDuplicates
      T.goldenTest "snaps/search-example-3.snap" $ teamSummary <$> results
  where
  teamSummary :: AssignmentResult -> _
  teamSummary team =
    team.characters
      # Map.values
      # Arr.fromFoldable
      <#>
        ( \character ->
            do
              let
                weapons = Arr.sort $ Arr.catMaybes
                  [ character.mainHand <#> _.weapon.name
                  , character.offHand <#> _.weapon.name
                  ]

              { character: character.name
              , weapons
              }
        )
      # Arr.sort

mkWeapon :: NonEmptyString -> NonEmptyString -> ArmoryWeapon
mkWeapon id character =
  { name: WeaponName id
  , character: CharacterName character
  , source: nes @"Gacha"
  , image: nes @" "
  , atbCost: 3
  , ob0: { description: nes @" ", effects: [] }
  , ob1: { description: nes @" ", effects: [] }
  , ob6: { description: nes @" ", effects: [] }
  , ob10: { description: nes @" ", effects: [] }
  , cureAllAbility: true
  , ignored: false
  }

filter1 :: Filter
filter1 =
  { effectType: FilterHeal
  , range: FilterAll
  }

filter2 :: Filter
filter2 =
  { effectType: FilterPatkDown
  , range: FilterSingleTargetOrAll
  }

filter3 :: Filter
filter3 =
  { effectType: FilterProvoke
  , range: FilterSelfOrSingleTargetOrAll
  }

filter4 :: Filter
filter4 =
  { effectType: FilterVeil
  , range: FilterSelfOrSingleTargetOrAll
  }

filter5 :: Filter
filter5 =
  { effectType: FilterIceResistDown
  , range: FilterAll
  }
