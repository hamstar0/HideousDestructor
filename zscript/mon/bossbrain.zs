// ------------------------------------------------------------
// The Tyrant
// ------------------------------------------------------------
class bossbrainspawnsource:hdactor{
	static void SpawnCluster(actor caller,vector3 pos,int stamina){
		let bbs=bossbrainspawnsource(spawn("bossbrainspawnsource",pos));
		bbs.master=caller;
		bbs.target=caller.target;
		bbs.stamina=stamina;
		int rnd=random(0,11);
		switch(rnd){
		case 0:
			if(!random(0,5)){
				bbs.accuracy=200;
				bbs.spawntype="Necromancer";
			}else{
				bbs.accuracy=100;
				bbs.spawntype="SkullSpitted";
			}
			break;
		case 1:
			bbs.accuracy=50;
			bbs.spawntype="PainLinger";
			break;
		case 2:
			bbs.accuracy=30;
			bbs.spawntype="Trilobite";
			break;
		case 3:
			bbs.accuracy=100;
			bbs.spawntype="SkullSpitted";
			break;
		case 4:
			bbs.accuracy=8;
			bbs.spawntype="Babstre";
			break;
		case 5:
			bbs.accuracy=12;
			bbs.spawntype="Putto";
			break;
		case 6:
			bbs.accuracy=16;
			bbs.spawntype="Yokai";
			break;
		case 7:
			bbs.accuracy=50;
			bbs.spawntype="CombatSlug";
			break;
		case 8:
			bbs.accuracy=50;
			bbs.spawntype="Technospider";
			break;
		case 9:
			bbs.accuracy=40;
			bbs.spawntype="Boner";
			break;
		default:
			bbs.accuracy=10;
			bbs.spawntype="ImpSpawner";
			break;
		}
	}
	enum BossSpawnFlags{
		BOSF_NOFLOOR=1,
		BOSF_NOTELE=2,
		BOSF_USEANGLE=4,
	}
	void A_SpawnMonsterType(int flags=0){
		if(!(flags&BOSF_NOFLOOR))setz(floorz);
		if(!(flags&BOSF_NOTELE))spawn("TeleFog",pos,ALLOW_REPLACE);
		let bbs=spawn(spawntype,pos,ALLOW_REPLACE);
		bbs.master=master;bbs.target=target;
		if(flags&BOSF_USEANGLE)bbs.angle=angle;else bbs.angle=frandom(0,360);
		stamina-=accuracy;
		if(stamina<1)destroy();
	}
	class<actor> spawntype;
	property spawntype:spawntype;
	default{
		+ismonster
		-shootable
		-solid
		+noblockmap
		bossbrainspawnsource.spawntype "ImpSpawner";
		accuracy 10;
		speed 16;
		maxstepheight 128;
		maxdropoffheight 128;
		renderstyle "add";
	}
	states{
	spawn:
		TNT1 A 0 nodelay setz(floorz);
		TNT1 AAAA 0 A_Wander();
		FIRE ABCDCDCDBCDEDCDEDCBCDEDCBCD 1 bright;
		FIRE EFGH 2 bright A_FadeOut(0.2);
	place:
		TNT1 AAAAAA 0 A_Wander();
		TNT1 A 1 A_SpawnMonsterType();
		loop;
	}
}
class HDBossCube:bossbrainspawnsource{
	default{
		projectile; -ismonster
		-noblockmap +shootable
		scale 0.666;
		radius 4;
		height 4;
		stamina 16;
		health 1;
		damagefunction (TELEFRAG_DAMAGE);
		projectilekickback 0;
		renderstyle "normal";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		setstatelabel("pain");
		bshootable=false;
		return -1;
	}
	states{
	spawn:
		BOSF A 0 nodelay A_PlaySound("brain/spit",CHAN_BODY,1,false,0.1);
		BOSF ABCD 3;
		BOSF A 0 A_SetSize(11,24);
	spawn2:
		BOSF ABCD 3;
		loop;
	pain:
		TNT1 AAAAA 0 A_SpawnItemEx("NecroShard",
			0,0,frandom(0,6),10,0,vel.z,flags:SXF_NOCHECKPOSITION
		);
		TNT1 A 0 A_SpawnItemEx("NecroGhostShard",
			0,0,frandom(0,6),10,0,vel.z,flags:SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION
		);
		TNT1 A 0 spawn("HDExplosion",pos,ALLOW_REPLACE);
		stop;
	death:
		TNT1 A 0{
			bshootable=true;
			if(target)master=target.master;
			if(master)target=master.target;
			A_SetRenderStyle(1.,STYLE_Add);
			scale=(1.,1.);
		}
		TNT1 A 0 A_SpawnMonsterType(BOSF_NOFLOOR|BOSF_NOTELE|BOSF_USEANGLE);
		FIRE ABCDCDCDBCDEDCDEDCBCDEDCBCD 1 bright;
		FIRE EFGH 2 bright A_FadeOut(0.2);
		stop;
	}
}
class HDBossBrain:HDMobBase replaces BossBrain{
	int paintimes;
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			!bshootable
			||(!source&&damage<TELEFRAG_DAMAGE)
			||(source&&source.master==self)
		)return -1;
		if(
			!bincombat
			||damage==TELEFRAG_DAMAGE
		){
			bshootable=false;
			setstatelabel("deathfade");
			return -1;
		}

		bshootable=false;
		paintimes++;

		int maxhp=skill+2;

		for(int i=0;i<MAXPLAYERS;i++){
			if(!playeringame[i])continue;
			maxhp++;
			if(
				players[i].mo
				&&players[i].mo.health>0
			){
				let pmo=players[i].mo;
				pmo.vel+=(pmo.pos-pos).unit()*7;
				pmo.vel.z+=3;
			}
		}
		if(paintimes>maxhp){
			setstatelabel("death");
			hdbosseye bbe;
			thinkeriterator bbem=ThinkerIterator.create("hdbosseye");
			while(bbe=hdbosseye(bbem.next(true))){
				bbe.remainingmessage="";
			}
		}else{
			setstatelabel("pain");
		}

		DistantQuaker.Quake(
			self,4,120,8192,10,
			HDCONST_SPEEDOFSOUND,
			HDCONST_MINDISTANTSOUND*2,
			HDCONST_MINDISTANTSOUND*4
		);

		return -1;
	}
	void A_SpawnWave(){
		array<actor> spots;spots.clear();
		bosstarget bpm;
		thinkeriterator bexpm=ThinkerIterator.create("bosstarget");
		int bbstamina=30+paintimes*8;
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i]){
				bbstamina+=10+paintimes;
				let pmo=players[i].mo;
				if(pmo&&pmo.health>0)spots.push(pmo);
			}
		}
		while(bpm=bosstarget(bexpm.next(true))){
			spots.push(actor(bpm));
		}
		for(int i=0;i<3;i++){
			if(!spots.size())break;
			int which=random(0,random(0,spots.size()-1));
			bossbrainspawnsource.SpawnCluster(self,spots[which].pos,bbstamina);
		}
		hdbosseye bbe;
		thinkeriterator bbem=ThinkerIterator.create("hdbosseye");
		while(bbe=hdbosseye(bbem.next(true))){
			bbe.setmessage();
			break;
		}
	}
	void A_DeathQuake(bool scream=true){
		if(scream)A_BrainPain();
		DistantQuaker.Quake(
			self,random(4,7),120,16384,10,
			HDCONST_SPEEDOFSOUND,
			16384,
			HDCONST_MINDISTANTSOUND*4
		);
	}
	default{
		+noblood
		+vulnerable
		+oldradiusdmg
	}
	override void postbeginplay(){
		paintimes=0;
		super.postbeginplay();
	}
	states{
	spawn:
		BBRN A -1;
		wait;
	pain:
		TNT1 AAAAAAAAAAAAAAAA 0 A_SpawnItemEx("TyrantWallSplodeDelayed",
			frandom(100,140),frandom(-30,30),frandom(64,82),
			frandom(4,20),0,frandom(-4,4),
			frandom(-1,1),SXF_NOCHECKPOSITION
		);
		MISL B 10;
		BBRN B 70 A_BrainPain();
		---- A 70 A_SpawnWave();
		---- A 0 A_SetShootable();
		goto spawn;
	death:
		MISL B 10;
		BBRN B 70 A_BrainPain();
		BBRN B 100;

		TNT1 AAAAAAA 0 A_SpawnItemEx("TyrantWallSplode",
			frandom(100,140),frandom(-30,30),frandom(64,82),
			frandom(20,30),0,frandom(-4,4),
			frandom(-2,2),SXF_NOCHECKPOSITION
		);

		BBRN A 20{
			A_DeathQuake(false);
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]&&players[i].mo)
					players[i].mo.A_GiveInventory("PowerFrightener");
			}
		}
		BBRN B 50 A_DeathQuake();
		BBRN B 40 A_DeathQuake();
		BBRN B 30 A_DeathQuake();
		BBRN B 20 A_DeathQuake();
		BBRN A 3{
			hdbosseye bbe;
			thinkeriterator bbem=ThinkerIterator.create("hdbosseye");
			while(bbe=hdbosseye(bbem.next(true))){
				bbe.playintro();
				break;
			}
		}
		BBRN BBBBB 10 A_DeathQuake();
		BBRN BBBB 6 A_BrainPain();

	xdeath:
		BBRN BBBBBB 3 A_BrainPain();
		TNT1 AAAAAAAAAAAAAAAA 0 A_SpawnItemEx("TyrantWallSplode",
			frandom(100,140),frandom(-30,30),frandom(64,82),
			frandom(20,30),0,frandom(-4,4),
			frandom(-2,2),SXF_NOCHECKPOSITION
		);
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("TyrantWallSplode",
			frandom(100,340),frandom(-100,100),frandom(-100,156),
			frandom(12,24),0,frandom(-4,4),
			frandom(-2,2),SXF_NOCHECKPOSITION
		);
		BBRN A 0 A_DeathQuake(false);
		BBRN A 0 A_PlaySound("brain/death",CHAN_BODY,1.0,false,ATTN_NONE);
		BBRN AAAAAAAA 3 A_SpawnItemEx("TyrantWallSplode",
			frandom(300,440),frandom(-300,300),frandom(-200,200),
			frandom(12,24),0,frandom(-4,4),
			frandom(-2,2),SXF_NOCHECKPOSITION
		);
		BBRN A 0{
			DistantQuaker.Quake(
				self,8,700,16384,10,
				HDCONST_SPEEDOFSOUND,
				16384,
				HDCONST_MINDISTANTSOUND*4
			);
		}
		BBRN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1{
			A_SetTics(randompick(0,0,0,1));
			A_SpawnItemEx("TyrantWallSplode",
				frandom(100,240),frandom(-600,600),frandom(-300,300),
				frandom(10,20),0,frandom(-2,2),
				frandom(-2,2),SXF_NOCHECKPOSITION
			);
		}
		BBRN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 A_SpawnItemEx("TyrantWallSplode",
			frandom(100,240),frandom(-500,500),frandom(-300,300),
			frandom(10,20),0,frandom(-2,2),
			frandom(-1,1),SXF_NOCHECKPOSITION
		);
		BBRN AAAAAAAAAAAAAAAAA 2 A_SpawnItemEx("TyrantWallSplode",
			random(100,240),random(-500,500),random(-300,300),
			random(10,20),0,random(-2,2),
			frandom(-1,1),SXF_NOCHECKPOSITION
		);
		BBRN A 0 A_BrainDie();
		BBRN AAAAAAAAAAA 6 A_SpawnItemEx("TyrantWallSplode",
			random(100,240),random(-500,500),random(-300,300),
			random(10,20),0,random(-2,2),
			frandom(-3,3),SXF_NOCHECKPOSITION,72
		);
		BBRN A -1;
		stop;

	deathfade:
		BBRN B 7;
		BBRN B 20 A_Scream();
		BBRN BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 1{binvisible=!binvisible;}
		TNT1 A 0 A_BrainDie();
		TNT1 A 10;
		TNT1 A 0 A_SetShootable();
		TNT1 A 0 SetStateLabel("spawn");
		stop;
	}
}


//explosion effects
class TyrantWallSplode:HDExplosion{
	states{
	spawn:
		TNT1 A 0 nodelay{
			scale*=frandom(1.3,2.);
			A_PlaySound ("world/explode",0,1.0,0,0.8);
			setz(frandom(floorz,ceilingz));
		}
		TNT1 AA 0 A_SpawnItemEx("HDSmokeChunk",
			0,0,0,
			vel.x+frandom(-12,12),vel.y+frandom(-12,12),vel.z+frandom(4,16),
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_ABSOLUTEMOMENTUM,96
		);
		TNT1 AAAAA 0 A_SpawnItemEx("HDSmoke",frandom(-24,24),frandom(-24,24),frandom(0,12));
		MISL BCDD 3 bright A_FadeOut (0.2);
		stop;
	}
}
class TyrantWallSplodeDelayed:HDExplosion{
	states{
	spawn:
		TNT1 A 1 nodelay A_SetTics(random(3,20));
		goto super::spawn;
	}
}



class HDBossEye:HDActor replaces BossEye{
	array<string> messages;
	array<string> intromessages;
	string remainingmessage;
	int messageticker;
	override void postbeginplay(){
		super.postbeginplay();
		remainingmessage="";
		messageticker=-1;

		//set brain to know this is a real boss and not just a pistol start hack
		bool foundbrain=false;
		hdbossbrain bpm;
		thinkeriterator bexpm=ThinkerIterator.create("hdbossbrain");
		while(bpm=hdbossbrain(bexpm.next(true))){
			bpm.bincombat=true;
			bpm.angle=bpm.angleto(self);
			if(!foundbrain)master=bpm;
			foundbrain=true;
		}
		if(!foundbrain){
			let bpm=spawn("hdbossbrain",pos);
			bpm.bincombat=true;
			bpm.angle=bpm.angleto(self);
			master=bpm;
		}

		string allmessages=Wads.ReadLump(Wads.CheckNumForName("bbtalk",0));

		//set up array of intros
		int dashpos=allmessages.indexof("---");
		if(dashpos<0){
			intromessages.clear();
		}else{
			string intros=allmessages.left(dashpos);
			intros.split(intromessages,"\n");
			for(int i=0;i<intromessages.size();i++){
				if(
					intromessages[i]==""
					||intromessages[i].left(2)=="//"
				){
					intromessages.delete(i);
					i--;
				}
			}
			allmessages=allmessages.mid(dashpos+3);
		}

		//set up array of messages
		allmessages.split(messages,"\n");
		if(messages[0]=="---")messages.delete(0);
		for(int i=0;i<messages.size();i++){
			if(
				messages[i]==""
				||messages[i].left(2)=="//"
			){
				messages.delete(i);
				i--;
			}
		}
	}
	//set the next message to play
	//the bossbrain should be finding the bosseye and calling this from its damagemobj
	void setmessage(){
		int msgsize=messages.size();
		if(!msgsize)return;
		msgsize=random(0,msgsize-1);
		if(remainingmessage=="")remainingmessage=messages[msgsize];
		else remainingmessage=remainingmessage.."||"..messages[msgsize];
		messages.delete(msgsize);
		messageticker=1;
	}
	void playintro(){
		int msgsize=intromessages.size();
		if(!msgsize)return;
		msgsize=random(0,msgsize-1);
		string thismessage=intromessages[msgsize];
		thismessage.replace("/","\n\n\cj");
		double messecs=max(2.,thismessage.length()*0.08);
		A_PrintBold("\cj"..thismessage,messecs,"BIGFONT");
		intromessages.delete(msgsize);
	}
	override void tick(){
		super.tick();

		//harass the player if they're doing too well
		if(
			!(level.time&(1|2|4|8|16|32|64|128|256|512|1024))
			&&target
			&&target.health>70
			&&checksight(target)
		)setstatelabel("missile");

		//see if there's a message to be played
		//countdown to next part of message
		if(
			!messageticker
			&&remainingmessage!=""
		){
			int nextpause=remainingmessage.indexof("|");
			string thismessage;
			if(nextpause<0){
				thismessage=remainingmessage;
				remainingmessage="";
			}else{
				thismessage=remainingmessage.left(nextpause);
				remainingmessage=remainingmessage.mid(nextpause+1);
			}
			thismessage.replace("/","\n\n\cj");
			double messecs=max(2.,thismessage.length()*0.08);
			if(
				thismessage!=""
				&&thismessage!=" "
			)A_PrintBold("\cj"..thismessage,messecs,"BIGFONT");
			messageticker+=messecs*35;
		}else if(messageticker>0)messageticker--;
	}
	default{
		-solid -shootable +noblockmap +lookallaround +nointeraction
		maxtargetrange 8192;
	}
	void A_ShootCube(){
		if(!target||!checksight(target))return;
		let ccc=spawn("HDBossCube",(pos.xy+angletovector(angleto(target),120),pos.z+3));
		ccc.target=self;ccc.master=master;
		ccc.vel=((target.pos-pos).unit()+(frandom(-0.1,0.1),frandom(-0.1,0.1),frandom(-0.1,0.1)))*8;
		ccc.A_FaceMovementDirection();

		bfg9k bpm;
		thinkeriterator bexpm=ThinkerIterator.create("bfg9k");
		while(bpm=bfg9k(bexpm.next(true))){
			bpm.InitializeWepStats(true);
		}
	}
	states{
	spawn:
		TNT1 A 10 A_Look();
		wait;
	see:
		TNT1 A 15 A_BrainAwake();
		TNT1 AAAAA 8 A_ShootCube();
		TNT1 A -1 playintro();
		stop;
	missile:
		TNT1 AAA 12 A_ShootCube();
		TNT1 A -1;
		stop;
	}
}


//randomspawners for the tyrant waves
class Babstre:RandomSpawner{
	default{
		+ismonster
		dropitem "Babuin",256,12;
		dropitem "SpecBabuin",256,3;
		dropitem "NinjaPirate",256,1;
	}
}
class PainLinger:RandomSpawner{
	default{
		+ismonster
		dropitem "PainLord",256,1;
		dropitem "PainBringer",256,4;
	}
}
class SkullSpitted:SkullSpitter{
	override void postbeginplay(){
		super.postbeginplay();
		for(int i=0;i<5;i++){
			A_SpawnItemEx(
				"FlyingSkull",
				50,0,frandom(0,10),
				0,0,0,
				frandom(0,360),
				SXF_TRANSFERPOINTERS|SXF_SETMASTER,
				32
			);
		}
	}
}










//yet another attempt
//this is good though
class ZomZom:ZombieMan{
	void A_TurnToFace(double threshold=30){
		if(
			!target
			||!checksight(target)
		){
			setstatelabel("see");
			return;
		}
		double totarg=angleto(target);
		double diff=deltaangle(angle,totarg);
		if(abs(diff)<max(0.1,threshold)){
			decidetoaim();
			setstatelabel("aim");
		}else angle+=threshold*frandom(0.6,1.6);
	}
	virtual void decidetoaim(){
		bhittarget=!random(0,5);
	}
	virtual void A_AimAtTarget(
		double threshold=1.,
		double projectilespeed=0,
		double projectilegravity=0,
		double shotheight=999
	){
		if(
			!target
			||!checksight(target)
		){
			setstatelabel("noshot");
			return;
		}
		if(threshold<=0)threshold=0.001;
		double totarg=angleto(target);
		double dist=distance3d(target);
		double dist2=distance2d(target);
		threshold*=1000./dist;

		double diff=deltaangle(angle,totarg);
		if(abs(diff)>max(threshold,30)){
			setstatelabel("turntoshoot");
			return;
		}else if(abs(diff)>frandom(0.001,threshold)){
			angle+=clamp(diff,-threshold,threshold)*frandom(0.6,1.6);
			return;
		}

		setstatelabel("shoot");

		//randomize pitch based on angle aim
		pitch=hdmath.pitchto(pos,target.pos);
		double finaldiff=absangle(angle,totarg);
		pitch+=frandom(-finaldiff,finaldiff);

		//lead the target
		if(
			projectilespeed>0
			&&target.vel!=(0,0,0)
		){
			vector3 leadpos=target.pos+target.vel;
			let ownpos=pos;
			double leadx1=hdmath.angleto(ownpos.xy,target.pos.xy);
			double leady1=hdmath.pitchto(ownpos,target.pos);
			double leadx2=hdmath.angleto(ownpos.xy,leadpos.xy);
			double leady2=hdmath.pitchto(ownpos,leadpos);
			double leadmult=frandom(0.1,1.3)*dist/projectilespeed;
			angle+=leadmult*deltaangle(leadx1,leadx2);
			pitch+=leadmult*deltaangle(leady1,leady2);
		}

		//compensate for drop
		if(
			projectilespeed>0
			&&projectilegravity>0
		){
			double gravtics=dist2/projectilespeed;
			double gravadjust=0;
			if(gravtics>1){
				for(int i=0;i<gravtics;i++){
					gravadjust-=i*projectilegravity;
				}
			}
			pitch+=atan2(gravadjust,dist2);
		}

		//readjust pitch for height of shot and centre of target
		double targheight=target.height*0.6;
		if(shotheight==999)shotheight=HDWeapon.GetShootOffset(self);
		pitch-=atan2(targheight-shotheight,dist2);
	}
	default{
		maxtargetrange 32000;
		+missilemore +missileevenmore
	}
	states{
	missile:
	turntoshoot:
		#### ABCD 4 A_TurnToFace();
		loop;
	aim:
		#### E 3 A_AimAtTarget(
			threshold:(bhittarget?1.:10.),
			projectilespeed:getdefaultbytype("HDB_9").speed,
			projectilegravity:getgravity()
		);
		loop;
	noshot:
		#### E 10;
		#### A 0 SetStateLabel("see");
	shoot:
		#### F 20 bright{HDBulletActor.FireBullet(self,"HDB_9");}
		#### A 0 SetStateLabel("see");
	}
}
