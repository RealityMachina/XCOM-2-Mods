// This is an Unreal Script
class X2Ability_Camaraderie extends X2Ability;

var localized string AimBonus, CritBonus, WillBonus, MobilityBonus, DefenseBonus, DodgeBonus, ArmorBonus, HackingBonus;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Camaraderie());

	return Templates;
}



static function X2AbilityTemplate Camaraderie()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_Camaraderie             CamaraderieEffect;
	local X2Condition_UnitProperty          MultiTargetProperty;
	local X2AbilityTrigger    Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Camaraderie');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_tacticalsense";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';

	CamaraderieEffect = new class'X2Effect_Camaraderie';
	CamaraderieEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
	CamaraderieEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	Template.AddMultiTargetEffect(CamaraderieEffect);

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	//Listener = new class'X2AbilityTrigger_EventListener';
	//Listener.ListenerData.Filter = eFilter_Unit;
	//Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	//Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	//Listener.ListenerData.EventID = 'UnitDied';
	//Template.AbilityTriggers.AddItem(Listener);

	//ShooterProperty = new class'X2Condition_UnitProperty';
	//ShooterProperty.ExcludeAlive = false;
	//ShooterProperty.ExcludeDead = false;
	//ShooterProperty.MinRank = default.VENGEANCE_MIN_RANK;
	//Template.AbilityShooterConditions.AddItem(ShooterProperty);

	MultiTargetProperty = new class'X2Condition_UnitProperty';
	MultiTargetProperty.ExcludeAlive = false;
	MultiTargetProperty.ExcludeDead = true;
	MultiTargetProperty.TreatMindControlledSquadmateAsHostile = true;
	MultiTargetProperty.ExcludeHostileToSource = true;
	MultiTargetProperty.ExcludeFriendlyToSource = false;
	MultiTargetProperty.RequireSquadmates = true;	
	MultiTargetProperty.ExcludePanicked = true;
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetProperty);

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Camaraderie_BuildVisualization;

	return Template;
}

function Camaraderie_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack TargetTrack, EmptyTrack;
	local XComGameState_Effect EffectState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver FlyOverAction;
	local int i;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect().EffectName != class'X2Effect_Camaraderie'.default.EffectName)
			continue;

		TargetTrack = EmptyTrack;
		UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		TargetTrack.StateObject_NewState = UnitState;
		TargetTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		TargetTrack.TrackActor = UnitState.GetVisualizer();

		for (i = 0; i < EffectState.StatChanges.Length; ++i)
		{
			FlyOverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(TargetTrack, VisualizeGameState.GetContext()));
			FlyOverAction.SetSoundAndFlyOverParameters(none, GetStringForCamaraderieStat(EffectState.StatChanges[i]), '', eColor_Good, , i == 0 ? 2.0f : 0.0f);
		}

		if (TargetTrack.TrackActions.Length > 0)
			OutVisualizationTracks.AddItem(TargetTrack);
	}
}

function string GetStringForCamaraderieStat(const StatChange CamaraderieStat)
{
	local string StatString;

	switch (CamaraderieStat.StatType)
	{
	case eStat_Offense:
		StatString = default.AimBonus;
		break;
	case eStat_CritChance:
		StatString = default.CritBonus;
		break;
	case eStat_Will:
		StatString = default.WillBonus;
		break;
	case eStat_Mobility:
		StatString = default.MobilityBonus;
		break;
	case eStat_Defense:
		StatString = default.DefenseBonus;
		break;
	case eStat_Dodge:
		StatString = default.DodgeBonus;
		break;
	case eStat_Hacking:
		StatString = default.HackingBonus;
		break;
	case eStat_ArmorMitigation:
		StatString = default.ArmorBonus;
		break;
	default:
		StatString = "UNKNOWN";
		`RedScreenOnce("Unhandled Camaraderie stat" @ CamaraderieStat.StatType @ "-jbouscher @gameplay");
		break;
	}
	StatString = repl(StatString, "<amount/>", int(CamaraderieStat.StatAmount));
	return StatString;
}