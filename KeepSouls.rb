#==============================================================================
# ** Keep Souls on Death for Cradle of Nightmare (RPG Maker VX Ace / RGSS3)
#------------------------------------------------------------------------------
#  When you die, the game runs common event 256 (死亡-魂掉落), which takes
#  25% of your souls. This script skips only that soul loss. Respawning,
#  the death counter, and spending souls anywhere else work as normal.
#
#  Works on its own; it doesn't need the God Mode script.
#
#  Install: insert a new slot directly ABOVE "Main" (the very last script).
#==============================================================================

module KeepSouls
  # Set to false to get the normal soul loss back.
  ENABLED = true

  # The common event that takes your souls on death.
  SOUL_DROP_EVENT = 256
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * "Change Gold": skip decreases while running the soul-drop event
  #--------------------------------------------------------------------------
  alias keepsouls_command_125 command_125
  def command_125
    if KeepSouls::ENABLED && @params[0] == 1 && keepsouls_in_drop_event?
      return
    end
    keepsouls_command_125
  end

  def keepsouls_in_drop_event?
    ce = $data_common_events[KeepSouls::SOUL_DROP_EVENT]
    ce && @list.equal?(ce.list)
  end
end