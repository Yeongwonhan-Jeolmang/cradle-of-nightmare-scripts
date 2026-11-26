#==============================================================================
# ** Infinite Items for Cradle of Nightmare (RPG Maker VX Ace / RGSS3)
#------------------------------------------------------------------------------
#  Using a consumable item (from the menu or in battle) no longer uses it up.
#  This includes the Cordyceps flasks, since they're items too.
#
#  Optional: skills that use up items (ammo) don't use them up either.
#
#  Not affected: items taken by events (keys, quest hand-ins), crafting
#  materials, selling.
#
#  Works on its own; it doesn't need the other scripts.
#
#  Install: insert a new slot directly ABOVE "Main" (the very last script).
#==============================================================================

module InfiniteItems
  # Set to false to turn this script off.
  ENABLED = true

  # Items used from the menu / battle Item command aren't used up.
  INFINITE_USABLE_ITEMS = true

  # Skills don't use up the items they need: bolts (99), arrows (100),
  # bullets (101), throwing knives (102), slingshot stones (103), etc.
  # You still need at least the required amount to use the skill.
  INFINITE_AMMO = true

  # Item IDs that should still get used up normally.
  EXCLUDE_ITEM_IDS = []

  def self.keep?(item)
    ENABLED && item.is_a?(RPG::Item) && !EXCLUDE_ITEM_IDS.include?(item.id)
  end
end

class Game_Party < Game_Unit
  attr_accessor :infiniteitems_paying_skill
  #--------------------------------------------------------------------------
  # * Using an item
  #--------------------------------------------------------------------------
  alias infiniteitems_consume_item consume_item
  def consume_item(item)
    return if InfiniteItems::INFINITE_USABLE_ITEMS && InfiniteItems.keep?(item)
    infiniteitems_consume_item(item)
  end
  #--------------------------------------------------------------------------
  # * Ammo: skills take items with gain_item(item, -amount)
  #--------------------------------------------------------------------------
  alias infiniteitems_gain_item gain_item
  def gain_item(item, amount, *args)
    if amount < 0 && @infiniteitems_paying_skill && InfiniteItems.keep?(item)
      return
    end
    infiniteitems_gain_item(item, amount, *args)
  end
end

class Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Mark when a skill is paying its costs, so only ammo is spared
  #--------------------------------------------------------------------------
  alias infiniteitems_pay_skill_cost pay_skill_cost
  def pay_skill_cost(skill)
    return infiniteitems_pay_skill_cost(skill) unless InfiniteItems::INFINITE_AMMO
    $game_party.infiniteitems_paying_skill = true
    begin
      infiniteitems_pay_skill_cost(skill)
    ensure
      $game_party.infiniteitems_paying_skill = false
    end
  end
end