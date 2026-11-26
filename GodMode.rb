#==============================================================================
# ** God Mode for Cradle of Nightmare (RPG Maker VX Ace / RGSS3)
#------------------------------------------------------------------------------
#  - Protected actors never lose HP to enemies, poison/burn/bleed ticks,
#    magic shield, "Change HP" events, drain, etc. Healing still works.
#  - Enemy MP and TP damage/drain is blocked (your own skill costs still apply).
#  - Debuffs (ATK down, DEF down...) never land.
#  - Every state an enemy tries to put on you is blocked, plus a list of
#    harmful states that can also come from events/build-up meters.
#  - Protected actors can never be knocked out.
#
#  Install: insert a new slot directly ABOVE "Main" (the very last script),
#  so this loads after every other custom script.
#==============================================================================

module GodMode
  # Master on/off switch.
  ENABLED = true

  # Actor IDs to protect. Empty [] = everyone in the party.
  # 1 = Yue Qing (the protagonist), 2 = Fang Yu, 7 = Glimmer...
  ACTOR_IDS = []

  # Block enemy MP / TP damage and drain.
  BLOCK_MP_DAMAGE = true
  BLOCK_TP_DAMAGE = true

  # true  = skills that cost HP still take their HP cost (fair).
  # false = HP costs are free too.
  ALLOW_HP_COSTS = true

  # Harmful states blocked no matter where they come from (enemy skills,
  # events, build-up meters, map traps). Enemy-inflicted states are blocked
  # anyway; this list catches the ones applied by events instead.
  # Remove an ID from this list if something story-related breaks.
  ALWAYS_BLOCK_STATES = [
    2,   # Poison
    3,   # Blind
    4,   # Slowed
    5,   # Confusion
    6,   # Drowsy / Sleep
    8,   # Stun
    11,  # Pre-battle stun (map ambush)
    12,  # Radiation
    27,  # Hemorrhage
    28,  # Bleed
    30,  # Agony
    32,  # Terror
    33,  # Toxic
    34,  # Strong restraint
    37,  # Stance broken
    42,  # Stance broken+
    46,  # Restraint
    47,  # Eye peeled
    54,  # Burning
    55,  # Chill / Cold
    56,  # Flash fire
    57,  # Fierce burning
    59,  # Fierce burning+
    69,  # Thin-ice freeze
    88,  # Guard broken
    89,  # Paralysis
    90,  # Paralysis build-up
    94,  # Daze 1
    95,  # Hallucination
    97,  # Daze 2
    98,  # Drowsy+
    100, # Crippled leg
    101, # Can't cast
    107, # Death sentence
    119, # Acid slime
    198, # Extreme weakness
    202, # Laceration
    211, # Magic stun
    240, # Weak poison
    245, # Wet (slowed)
    247, # Petrified
    248, # Petrifying
    268, # Terror spread
    272, # Oiled
    278, # Slime
    355, # Toxic smoke
    415, # Decay
    419, # Decay (player)
    471, # Crossbow instant-death mark
    480, # Mark of death
    540, # Paranoia
    541, # Fire PTSD
    543, # Blood loss
    580, # Spell block
    581, # Spell block (supreme)
    636, 637, 638, 639, 640, 641, 642, 643, 644, 645, # Death chill
    647, # Internal injury
    648, # Acid weak-point exposed
    656, # Black moth swarm (on player)
    769, # Vital damaged
    786, # Scald
    803, # Poisoned marrow
    820, # Drowsy+
    854, # Ring corrosion
  ]

  # Block scripted deaths outside of HP: traps, headshots, the Horror
  # (骇死) meter filling up, mimic chests, electric shocks, etc.
  BLOCK_SCRIPTED_DEATHS = true

  # Common events that kill the player in this game:
  #   6   ★死亡           the death/respawn sequence everything funnels into
  #   34  ★陷阱 死亡判定  trap death roll (50% chance)
  #   70  ▲骇死成功       Horror meter full -> death
  #   187 宝箱怪          mimic chest death cutscene
  #   188 爆头死          headshot death
  DEATH_EVENTS = [6, 34, 70, 187, 188]

  def self.protects?(battler)
    return false unless ENABLED && battler && battler.actor?
    ACTOR_IDS.empty? || ACTOR_IDS.include?(battler.id)
  end

  def self.block_death_event?(id)
    BLOCK_SCRIPTED_DEATHS && DEATH_EVENTS.include?(id) &&
      $game_party && protects?($game_party.leader)
  end

  # Undo whatever the trap/meter set up before the death call, so the
  # game doesn't stay frozen or black.
  def self.after_blocked_death
    $game_switches[371] = false  # ●骇死 (Horror death trigger)
    $game_switches[461] = false  # ●陷阱死开关 (trap death switch)
    $game_switches[52]  = false  # 【禁用/定身】 (player frozen)
    $game_switches[133] = false  # 【死亡演出定身】 (frozen for death scene)
    $game_variables[31] = 0      # 【●骇死条】 Horror meter
    $game_variables[32] = 0      # ●陷阱 死亡判定 trap death roll
    screen = $game_party.in_battle ? $game_troop.screen : $game_map.screen
    screen.start_fadein(30) if screen.brightness < 255
  end
end

#==============================================================================
# ** Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Apply an action to us: remember the attacker, and afterwards undo any
  #   HP/MP/TP loss that slipped through (e.g. magic shield edits @hp
  #   directly).
  #--------------------------------------------------------------------------
  alias godmode_item_apply item_apply
  def item_apply(user, item)
    protect = GodMode.protects?(self)
    old_hp, old_mp, old_tp = @hp, @mp, @tp
    @godmode_attacker = user
    godmode_item_apply(user, item)
    if protect
      @hp = old_hp if @hp < old_hp
      if user && user.enemy?
        @mp = old_mp if GodMode::BLOCK_MP_DAMAGE && @mp < old_mp
        @tp = old_tp if GodMode::BLOCK_TP_DAMAGE && @tp < old_tp
      end
    end
  ensure
    @godmode_attacker = nil
  end
  #--------------------------------------------------------------------------
  # * Zero out incoming damage numbers (healing still works)
  #--------------------------------------------------------------------------
  alias godmode_make_damage_value make_damage_value
  def make_damage_value(user, item)
    godmode_make_damage_value(user, item)
    return unless GodMode.protects?(self)
    if @result.hp_damage > 0
      @result.hp_damage = 0
      @result.hp_drain  = 0
    end
    if GodMode::BLOCK_MP_DAMAGE && @result.mp_damage > 0
      @result.mp_damage = 0
      @result.mp_drain  = 0
    end
    if GodMode::BLOCK_TP_DAMAGE && @result.tp_damage > 0
      @result.tp_damage = 0
      @result.tp_drain  = 0 if @result.respond_to?(:tp_drain=)
    end
  end
  #--------------------------------------------------------------------------
  # * Slip damage (poison, burn, bleed) shows/does nothing
  #--------------------------------------------------------------------------
  alias godmode_regenerate_hp regenerate_hp
  def regenerate_hp
    godmode_regenerate_hp
    if GodMode.protects?(self) && @result.hp_damage > 0
      @result.hp_damage = 0
    end
  end
  #--------------------------------------------------------------------------
  # * Let skill HP costs through if configured
  #--------------------------------------------------------------------------
  alias godmode_pay_skill_cost pay_skill_cost
  def pay_skill_cost(skill)
    @godmode_paying_cost = GodMode::ALLOW_HP_COSTS
    godmode_pay_skill_cost(skill)
  ensure
    @godmode_paying_cost = false
  end
  #--------------------------------------------------------------------------
  # * Block debuffs
  #--------------------------------------------------------------------------
  alias godmode_add_debuff add_debuff
  def add_debuff(param_id, turns)
    return if GodMode.protects?(self)
    godmode_add_debuff(param_id, turns)
  end
  #--------------------------------------------------------------------------
  # * Block knockout, enemy-inflicted states, and listed harmful states
  #--------------------------------------------------------------------------
  def godmode_block_state?(state_id)
    return false unless GodMode.protects?(self)
    return true if state_id == death_state_id
    return true if GodMode::ALWAYS_BLOCK_STATES.include?(state_id)
    return true if @godmode_attacker && @godmode_attacker.enemy?
    false
  end

  alias godmode_add_state add_state
  def add_state(state_id)
    return if godmode_block_state?(state_id)
    godmode_add_state(state_id)
  end

  alias godmode_add_new_state add_new_state
  def add_new_state(state_id)
    return if godmode_block_state?(state_id)
    godmode_add_new_state(state_id)
  end
end

#==============================================================================
# ** Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * Catch-all: HP can never go down (events, traps, other scripts)
  #--------------------------------------------------------------------------
  alias godmode_hp_set hp=
  def hp=(value)
    if GodMode.protects?(self) && @hp && value < @hp && !@godmode_paying_cost
      value = @hp
    end
    godmode_hp_set(value)
  end
  #--------------------------------------------------------------------------
  # * No damage-floor damage or screen flash
  #--------------------------------------------------------------------------
  alias godmode_execute_floor_damage execute_floor_damage
  def execute_floor_damage
    return if GodMode.protects?(self)
    godmode_execute_floor_damage
  end
end

#==============================================================================
# ** Game_Interpreter - skip "Call Common Event" for death events
#==============================================================================
class Game_Interpreter
  alias godmode_command_117 command_117
  def command_117
    if GodMode.block_death_event?(@params[0])
      GodMode.after_blocked_death
      return
    end
    godmode_command_117
  end
end

#==============================================================================
# ** Game_Temp - drop death events queued by skills/items
#==============================================================================
class Game_Temp
  alias godmode_reserve_common_event reserve_common_event
  def reserve_common_event(common_event_id)
    if GodMode.block_death_event?(common_event_id)
      GodMode.after_blocked_death
      return
    end
    godmode_reserve_common_event(common_event_id)
  end
end

#==============================================================================
# ** Game_CommonEvent - stop parallel death events (Horror meter death)
#==============================================================================
class Game_CommonEvent
  alias godmode_active? active?
  def active?
    if @event && GodMode.block_death_event?(@event.id) && godmode_active?
      GodMode.after_blocked_death
      return false
    end
    godmode_active?
  end
end