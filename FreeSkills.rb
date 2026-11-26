#==============================================================================
# ** Free Skills for Cradle of Nightmare (RPG Maker VX Ace / RGSS3)
#------------------------------------------------------------------------------
#  Your skills, spells and abilities cost 0 MP and 0 TP. You can use them
#  even with empty MP/TP, and the cost shows as nothing in menus.
#
#  Only affects your party; enemies still pay their costs. Other costs
#  (HP, souls, items, cooldowns) are unchanged.
#
#  Works on its own; it doesn't need the God Mode script.
#
#  Install: insert a new slot directly ABOVE "Main" (the very last script).
#==============================================================================

module FreeSkills
  # Set to false to turn this script off.
  ENABLED = true

  # Which costs to remove.
  FREE_MP = true
  FREE_TP = true

  # Actor IDs that get free skills. Empty [] = everyone in the party.
  # 1 = Yue Qing (the protagonist).
  ACTOR_IDS = []

  def self.applies?(actor)
    ENABLED && (ACTOR_IDS.empty? || ACTOR_IDS.include?(actor.id))
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * MP cost: 0 (this is what the game checks, charges, and displays)
  #--------------------------------------------------------------------------
  alias freeskills_skill_mp_cost skill_mp_cost
  def skill_mp_cost(skill)
    return 0 if FreeSkills::FREE_MP && FreeSkills.applies?(self)
    freeskills_skill_mp_cost(skill)
  end
  #--------------------------------------------------------------------------
  # * TP cost: 0
  #--------------------------------------------------------------------------
  alias freeskills_skill_tp_cost skill_tp_cost
  def skill_tp_cost(skill)
    return 0 if FreeSkills::FREE_TP && FreeSkills.applies?(self)
    freeskills_skill_tp_cost(skill)
  end
end