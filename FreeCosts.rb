#==============================================================================
# ** Free Costs for Cradle of Nightmare (RPG Maker VX Ace / RGSS3)
#------------------------------------------------------------------------------
#  - Shops: everything costs 0 souls. Selling still pays you.
#  - Crafting (Normal/Special/Soul Upgrade, Resonant Shaping) and the
#    shop-style "compose" menus: materials aren't needed or used up.
#    The weapon/armor you're upgrading is still required and replaced,
#    so upgrades don't duplicate gear (change below if you want).
#  - Event soul costs: leveling up at flower baskets, NPC services, etc.
#    don't take your souls.
#
#  Works on its own; it doesn't need the other scripts.
#
#  Install: insert a new slot directly ABOVE "Main" (the very last script).
#==============================================================================

module FreeCosts
  # Set to false to turn this whole script off.
  ENABLED = true

  # Shop purchases cost 0 souls.
  FREE_SHOP_PRICES = true

  # Crafting / compose menus don't need or use up materials.
  FREE_CRAFTING = true

  # When crafting, still require and use up the weapon/armor being upgraded.
  # false = you also keep the old one (and can craft without owning it).
  KEEP_BASE_EQUIPMENT_COST = true

  # Events that take souls (leveling up, NPC services, ...) take nothing.
  # Note: you still need to HAVE enough souls where the game checks first,
  # e.g. leveling up asks how many souls to spend and checks you have them.
  FREE_EVENT_SOUL_COSTS = true

  # Switch that turns a shop into a "compose" (crafting) shop.
  COMPOSE_SWITCH = 11

  def self.on?(option)
    ENABLED && option
  end
end

#==============================================================================
# ** Shops
#==============================================================================
class Scene_Shop < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Price paid per item: 0 (also lifts the "how many can I afford" limit)
  #--------------------------------------------------------------------------
  alias freecosts_buying_price buying_price
  def buying_price
    return 0 if FreeCosts.on?(FreeCosts::FREE_SHOP_PRICES)
    freecosts_buying_price
  end
  #--------------------------------------------------------------------------
  # * Compose shops: don't limit quantity by materials, don't use them up
  #--------------------------------------------------------------------------
  alias freecosts_max_buy max_buy
  def max_buy
    freecosts_without_compose { freecosts_max_buy }
  end

  alias freecosts_do_buy do_buy
  def do_buy(number)
    freecosts_without_compose { freecosts_do_buy(number) }
  end

  def freecosts_without_compose
    return yield unless FreeCosts.on?(FreeCosts::FREE_CRAFTING)
    sid = FreeCosts::COMPOSE_SWITCH
    old = $game_switches[sid]
    $game_switches[sid] = false
    begin
      yield
    ensure
      $game_switches[sid] = old
    end
  end
end

class Window_ShopBuy < Window_Selectable
  #--------------------------------------------------------------------------
  # * Items aren't greyed out for lack of souls or materials
  #--------------------------------------------------------------------------
  alias freecosts_enable? enable?
  def enable?(item)
    return freecosts_enable?(item) unless FreeCosts::ENABLED
    return false unless item && !$game_party.item_max?(item)
    unless FreeCosts::FREE_SHOP_PRICES
      return false unless price(item) <= @money
    end
    unless FreeCosts::FREE_CRAFTING
      return false if respond_to?(:composable?) && !composable?(item)
    end
    true
  end
end

#==============================================================================
# ** Crafting menu (Mr. Trivel crafting + English patch)
#==============================================================================
if defined?(MrTS_Requirements_Window)
class MrTS_Requirements_Window < Window_Base
  alias freecosts_craft_item craft_item
  def craft_item
    return freecosts_craft_item unless FreeCosts.on?(FreeCosts::FREE_CRAFTING)
    return unless @item_list
    party = $game_party
    count = lambda { |it| party.respond_to?(:craft_item_number) ?
                          party.craft_item_number(it) : party.item_number(it) }
    # Only the weapon/armor being upgraded counts as a cost now
    base = @item_list.select { |il| il[0].is_a?(RPG::EquipItem) }
    base = [] unless FreeCosts::KEEP_BASE_EQUIPMENT_COST
    base.each do |il|
      if count.call(il[0]) < il[1]
        Sound.play_buzzer
        return
      end
    end
    freed = []
    base.each do |il|
      if party.respond_to?(:craft_consume)
        freed.concat(party.craft_consume(il[0], il[1]))
      else
        party.lose_item(il[0], il[1])
      end
    end
    recipe = MrTS::Crafting::RECIPES[@recipe]
    geto = get_true_item(recipe[:item])
    party.gain_item(geto[0], geto[1])
    party.craft_auto_equip(geto[0], freed) if party.respond_to?(:craft_auto_equip)
    party.add_craft_exp(recipe[:discipline], recipe[:exp])
  end
end
end

#==============================================================================
# ** Events: "Change Gold" decreases do nothing
#==============================================================================
class Game_Interpreter
  alias freecosts_command_125 command_125
  def command_125
    return if FreeCosts.on?(FreeCosts::FREE_EVENT_SOUL_COSTS) && @params[0] == 1
    freecosts_command_125
  end
end