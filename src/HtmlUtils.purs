module HtmlUtils where

import Prelude

import Core.Database.VLatest (Weapon)
import Core.Display (display)
import Data.String.Utils as String
import Halogen (AttrName(..), ClassName(..))
import Halogen.HTML (HTML, IProp)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

classes' :: forall r i. String -> IProp (class :: String | r) i
classes' str =
  HP.classes $ ClassName <$> String.words str

tooltip :: forall r i. String -> IProp r i
tooltip text = HH.attr (AttrName "data-tooltip") text

mkTooltipForWeapon :: Weapon -> String
mkTooltipForWeapon weapon =
  cureAllNote
    <> "OB0:\n"
    <> display weapon.ob0.description
    <> "\n\nOB6:\n"
    <> display weapon.ob6.description

  where
  cureAllNote =
    if weapon.cureAllAbility then "Has 'All (Cure Spells)' S. Ability\n\n"
    else ""

displayIf :: forall w i. Boolean -> HTML w i -> HTML w i
displayIf cond html =
  if cond then html else HH.text ""
