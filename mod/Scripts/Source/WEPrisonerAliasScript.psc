Scriptname WEPrisonerAliasScript extends ReferenceAlias
{MKF - Free Prisoners: the bound prisoner of the random encounters "Thalmor with Prisoner" (WE32) and "Imperials
with Stormcloak Prisoner" (WE09). Vanilla asked "Free Prisoner?" in a message box. With the Modifier Key Framework,
Activate makes the prisoner plead, and the modifier key frees them: Free, or Free and Give Items (their inventory
opens and the world runs slowly until it closes).

Written for this mod, not copied from vanilla or any patch. The properties keep vanilla's names and types, so the
encounter quests fill them as before and need no override. This mod's own records are read from its plugin.}

Topic Property WESharedDialoguePrisonerSetFree Auto
Idle Property OffsetBoundStandingStart Auto
Idle Property OffsetStop Auto
Message Property WEPrisonerMessageBox Auto
Faction Property WEPrisonerFreedFaction Auto
Faction Property WEPrisonerFreedCombatCaptorFaction Auto
Faction Property WEPrisonerFreedCombatPrisonerFaction Auto
ReferenceAlias Property Captor1 Auto
ReferenceAlias Property Captor2 Auto
ReferenceAlias Property Captor3 Auto
ReferenceAlias Property Captor4 Auto
ReferenceAlias Property Captor5 Auto

Bool bound = True
Bool freeingAfterMenu = False
Bool liberatorIsPlayer = True

String Property ThisPlugin = "MKF - Free Prisoners.esp" AutoReadOnly
Int Property BoundFactionID = 0x800 AutoReadOnly
Int Property PleadTopicID = 0x802 AutoReadOnly
Int Property SlowTimeSpellID = 0x809 AutoReadOnly

; ---------------------------------------------------------------------------------------------------------------
; Setup. Mod event registrations don't survive a save load: the prisoner's 3D loads again after every load
; (OnLoad), which registers them again.

Event OnInit()
	Prepare()
EndEvent

Event OnLoad()
	Prepare()
	Actor prisoner = GetActorReference()
	If bound && prisoner
		prisoner.PlayIdle(OffsetBoundStandingStart)
	EndIf
EndEvent

Function Prepare()
	RegisterForModEvent("MKFFP_Plead", "OnPlead")
	RegisterForModEvent("MKFFP_Free", "OnFree")
	MarkBound()
EndFunction

; The framework's rule matches members of this mod's faction: in it while bound, out of it once freed. The rank
; tells the dialogue whether the captors still live (0) or are all dead (1).
Function MarkBound()
	Actor prisoner = GetActorReference()
	Faction boundFaction = Game.GetFormFromFile(BoundFactionID, ThisPlugin) As Faction
	If !prisoner || !boundFaction
		Return
	EndIf
	If bound && !prisoner.IsDead()
		Int rank = 1
		If AnyCaptorAlive()
			rank = 0
		EndIf
		prisoner.SetFactionRank(boundFaction, rank)
	Else
		prisoner.RemoveFromFaction(boundFaction)
	EndIf
EndFunction

; ---------------------------------------------------------------------------------------------------------------
; Activation

; Without the framework, keep vanilla's message box so the prisoner can still be freed.
Event OnActivate(ObjectReference akActionRef)
	If SKSE.GetPluginVersion("ModifierKeyFramework") > 0
		Return
	EndIf
	Actor prisoner = GetActorReference()
	If !bound || !prisoner || prisoner.IsDead() || prisoner.IsInCombat() || !WEPrisonerMessageBox
		Return
	EndIf
	Int choice = WEPrisonerMessageBox.Show()
	If choice == 1
		FreePrisoner(prisoner, True, False)
	ElseIf choice == 2
		FreePrisoner(prisoner, True, True)
	EndIf
EndEvent

; Activate: the prisoner pleads (one of the lines for captors alive or dead).
Event OnPlead(String asEventName, String asRuleId, Float afAction, Form akTarget)
	Actor prisoner = GetActorReference()
	If !prisoner || akTarget != prisoner || !bound
		Return
	EndIf
	MarkBound()
	Topic plead = Game.GetFormFromFile(PleadTopicID, ThisPlugin) As Topic
	If plead
		prisoner.Say(plead)
	EndIf
EndEvent

; Modifier actions: 1 = Free, 2 = Free and Give Items.
Event OnFree(String asEventName, String asRuleId, Float afAction, Form akTarget)
	Actor prisoner = GetActorReference()
	If !prisoner || akTarget != prisoner || !bound || prisoner.IsDead() || prisoner.IsInCombat()
		Return
	EndIf
	FreePrisoner(prisoner, True, afAction >= 2.0)
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked)
	If akAggressor == Game.GetPlayer()
		Game.GetPlayer().AddToFaction(WEPrisonerFreedCombatPrisonerFaction)
		TurnCaptors()
	EndIf
EndEvent

; ---------------------------------------------------------------------------------------------------------------
; Freeing. Same signature as vanilla's, which the encounter quests' own scripts may call.

Function FreePrisoner(Actor ActorRef, Bool playerIsLiberator = True, Bool OpenInventory = False)
	If !ActorRef || !bound
		Return
	EndIf
	bound = False
	liberatorIsPlayer = playerIsLiberator
	MarkBound()
	ActorRef.AddToFaction(WEPrisonerFreedFaction)
	ActorRef.AddToFaction(WEPrisonerFreedCombatPrisonerFaction)
	; the bound pose holds until something ends it: end it here, or the freed prisoner keeps their hands tied
	If OffsetStop
		ActorRef.PlayIdle(OffsetStop)
	EndIf
	ActorRef.EvaluatePackage()

	If OpenInventory
		; the world runs slowly while the inventory is open (it only matters when menus don't pause the game);
		; the thanks and the captors' turn come when it closes
		Spell slowTime = Game.GetFormFromFile(SlowTimeSpellID, ThisPlugin) As Spell
		If slowTime
			slowTime.Cast(Game.GetPlayer(), Game.GetPlayer())
		EndIf
		freeingAfterMenu = True
		RegisterForMenu("ContainerMenu")
		ActorRef.OpenInventory(True)
		Utility.WaitMenuMode(0.5)
		If freeingAfterMenu && !UI.IsMenuOpen("ContainerMenu")
			FinishFreeing()   ; the inventory never opened
		EndIf
	Else
		FinishFreeing()
	EndIf
EndFunction

Event OnMenuClose(String asMenuName)
	If asMenuName == "ContainerMenu" && freeingAfterMenu
		FinishFreeing()
	EndIf
EndEvent

Function FinishFreeing()
	freeingAfterMenu = False
	UnregisterForMenu("ContainerMenu")
	Spell slowTime = Game.GetFormFromFile(SlowTimeSpellID, ThisPlugin) As Spell
	If slowTime
		Game.GetPlayer().DispelSpell(slowTime)
	EndIf
	Actor prisoner = GetActorReference()
	If liberatorIsPlayer
		Game.GetPlayer().AddToFaction(WEPrisonerFreedCombatPrisonerFaction)
	EndIf
	TurnCaptors()
	If prisoner
		prisoner.Say(WESharedDialoguePrisonerSetFree)
		prisoner.EvaluatePackage()
	EndIf
EndFunction

; Call when the quest shuts down.
Function ClearFactions()
	Game.GetPlayer().RemoveFromFaction(WEPrisonerFreedCombatPrisonerFaction)
	TryToRemoveFromFaction(WEPrisonerFreedCombatCaptorFaction)
	Faction boundFaction = Game.GetFormFromFile(BoundFactionID, ThisPlugin) As Faction
	If boundFaction
		TryToRemoveFromFaction(boundFaction)
	EndIf
	CaptorLeaves(Captor1)
	CaptorLeaves(Captor2)
	CaptorLeaves(Captor3)
	CaptorLeaves(Captor4)
	CaptorLeaves(Captor5)
EndFunction

; ---------------------------------------------------------------------------------------------------------------
; Captors (WE32 fills only three of the five)

Function TurnCaptors()
	CaptorTurns(Captor1)
	CaptorTurns(Captor2)
	CaptorTurns(Captor3)
	CaptorTurns(Captor4)
	CaptorTurns(Captor5)
EndFunction

Function CaptorTurns(ReferenceAlias captor)
	If captor
		captor.TryToAddToFaction(WEPrisonerFreedCombatCaptorFaction)
	EndIf
EndFunction

Function CaptorLeaves(ReferenceAlias captor)
	If captor
		captor.TryToRemoveFromFaction(WEPrisonerFreedCombatCaptorFaction)
	EndIf
EndFunction

Bool Function AnyCaptorAlive()
	Return CaptorAlive(Captor1) || CaptorAlive(Captor2) || CaptorAlive(Captor3) || CaptorAlive(Captor4) || CaptorAlive(Captor5)
EndFunction

Bool Function CaptorAlive(ReferenceAlias captor)
	If !captor
		Return False
	EndIf
	Actor who = captor.GetActorReference()
	Return who && !who.IsDead()
EndFunction
