#==============================================================================
# ** Infinite Cordyceps Flasks for Cradle of Nightmare (RPG Maker VX Ace)
#------------------------------------------------------------------------------
#  Drinking a Cordyceps flask (冬虫卵形瓶) no longer uses up a charge.
#  Other items are used up as normal.
#
#  The flasks are items 1 (red) and 2 (blue). The game refills them to your
#  maximum when you rest or die, and that still works.
#
#  Works on its own; it doesn't need the other scripts.
#
#  Install: insert a new slot directly ABOVE "Main" (the very last script).
#==============================================================================

module InfiniteFlasks
  # Set to false to turn this script off.
  ENABLED = true

  # 1 = red Cordyceps flask (HP), 2 = blue Cordyceps flask (MP).
  FLASK_ITEM_IDS = [1, 2]
end

class Game_Party < Game_Unit
  alias infiniteflasks_consume_item consume_item
  def consume_item(item)
    if InfiniteFlasks::ENABLED && item.is_a?(RPG::Item) &&
       InfiniteFlasks::FLASK_ITEM_IDS.include?(item.id)
      return
    end
    infiniteflasks_consume_item(item)
  end
end