try{var AN_TAG_LIB=function AN_taqgingObject(){var S=navigator.userAgent.toLowerCase();
this.browser={version:(S.match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/)||[])[1],safari:/webkit/.test(S),opera:/opera/.test(S),msie:/msie/.test(S)&&!/opera/.test(S),mozilla:/mozilla/.test(S)&&!/(compatible|webkit)/.test(S),chrome:/chrome/.test(S)};
var H="4.1.8";
var f=new Array();
var b=new Array();
var O=new Array();
var B=true;
var F=0;
var q=0;
var m=new Array();
var N=new Array();
var y=0;
var d=0;
var u=false;
var C=new Date();
var ao;
var e=true;
var G=false;
var ak=new Array();
var k;
var U;
var p;
var r=new Array();
var l;
var aj=0;
var c=0;
var V=false;
var o=false;
var I=false;
var g=false;
var ac=false;
var aa="anTD4";
var h="anTRD";
var T="anTHS";
var n="optout";
var E=":";
var Q=",";
var M="#";
var A="|";
var an="_";
var s="<VALUE>";
var ae="<TERMS>";
var ab="<RND>";
var a="<VID>";
var am=new RegExp(a,"gi");
var ah="<VID_E64>";
var t=new RegExp(ah,"gi");
var ai="<3RDPARTYIDS>";
var j=1;
var ag=2;
var Z=3;
var ad=1;
var Y=2;
var z=3;
var D=1;
var L=2;
var X=3;
var R=3000;
var K=5;
var P=1440;
var i=2;
var x="https://pbid.pro-market.net/engine?site=<PPID>;mimetype=img;ddar";
var J=".pro-market.net";
var w="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ";
var al=7;
var W=90;
var v=999998;
this.AN_StaticCategoryNetworks=function(at,aq,au,ap,av,ar){this.catID=at;
this.catTimeFactor=aq;
this.networks=au;
this.expireDate=ap;
this.parentId=av;
this.segPriority=ar
};
this.AN_StaticPP=function(ap,ar,aw,av,aq,au,at){this.profileProvider=ap;
this.ppType=ar;
this.maxTags=aw;
this.isBackGroundRedirect=av;
this.backGroundedirectInterval=aq;
this.backGroundeMaxredirect=Number(au);
this.groupRedirectInterval=at;
this.isGroupRedirect=(this.groupRedirectInterval>0)
};
this.AN_StaticNetwork=function(aq,av,aB,ay,az,aC,at,au,ax,aw,aD,aA,ar,ap){this.id=aq;
this.active=av;
this.disabled=false;
this.dataType=aB;
this.DuCatIdType=ay;
this.encodeKey=az;
this.networkUrl=aC;
this.networkSecuredUrl=at;
this.htmlType=au;
this.maxTermsInURL=ax;
this.termDelimiter=aD;
this.distributionDelay=aw;
this.priority=aA;
this.externalRedirects=ar;
this.anCategoriesToNetworkCategories=ap
};
this.CookieSyncTag=function(au,ar,at,aq,ap){this.dataUserId=au;
this.DuPriority=ar;
this.isCSync=true;
this.tagType=at;
this.dataUserSecuredUrl=aq;
this.dataUserCSyncDays=ap
};
this.ProspectSyncNetwork=function(ap){this.networkId=ap;
this.isProspect=false
};
m._107648=new AN_StaticPP(107648,i,0,true,200,4,0);
m._110930=new AN_StaticPP(110930,i,16,false,0,0,0);
m._119694=new AN_StaticPP(119694,i,4,false,0,0,0);
m._121321=new AN_StaticPP(121321,i,4,false,0,0,0);
m._121322=new AN_StaticPP(121322,i,4,false,0,0,0);
m._122270=new AN_StaticPP(122270,i,0,true,200,4,0);
m._125361=new AN_StaticPP(125361,i,16,false,0,0,0);
m._131894=new AN_StaticPP(131894,i,4,false,0,0,0);
m._133036=new AN_StaticPP(133036,i,4,false,0,0,0);
f._1=new AN_StaticNetwork(1,false,j,X,0,"not_data_DU","",ad,1,0,"",5,0,{});
f._10=new AN_StaticNetwork(10,false,j,X,0,"not_data_DU","",ad,1,0,"",14,0,{});
f._13=new AN_StaticNetwork(13,false,j,X,0,"not_data_DU","",ad,1,0,"",4,2,{});
f._18=new AN_StaticNetwork(18,false,j,X,0,"not_data_DU","",ad,1,0,"",20,0,{});
f._19=new AN_StaticNetwork(19,false,j,X,0,"not_data_DU","",ad,1,0,"",16,0,{});
f._20=new AN_StaticNetwork(20,false,j,X,0,"not_data_DU","",ad,1,0,"",0,0,{});
f._22=new AN_StaticNetwork(22,false,j,X,0,"not_data_DU","",ad,1,0,"",0,0,{});
f._23=new AN_StaticNetwork(23,false,j,X,0,"not_data_DU","",ad,1,0,"",0,0,{});
f._24=new AN_StaticNetwork(24,false,j,X,0,"not_data_DU","",ad,1,0,"",10,0,{});
f._25=new AN_StaticNetwork(25,false,j,X,0,"not_data_DU","",ad,1,0,"",18,0,{});
f._26=new AN_StaticNetwork(26,false,j,X,0,"not_data_DU","",ad,1,0,"",0,0,{});
f._33=new AN_StaticNetwork(33,false,j,D,0,"not_data_DU","",ad,1,0,"",1,0,{});
f._53=new AN_StaticNetwork(53,false,j,X,0,"not_data_DU","",ad,1,0,"",2,0,{});
f._67=new AN_StaticNetwork(67,false,j,X,0,"not_data_DU","",ad,1,0,"",17,0,{});
f._73=new AN_StaticNetwork(73,false,j,D,0,"not_data_DU","",ad,1,0,"",3,0,{});
f._81=new AN_StaticNetwork(81,false,j,X,0,"not_data_DU","",ad,1,0,"",11,0,{});
f._85=new AN_StaticNetwork(85,false,j,D,0,"not_data_DU","",ad,1,0,"",9,0,{});
f._88=new AN_StaticNetwork(88,false,j,X,0,"not_data_DU","",ad,1,0,"",19,0,{});
f._89=new AN_StaticNetwork(89,false,j,X,0,"not_data_DU","",ad,1,0,"",6,0,{});
f._91=new AN_StaticNetwork(91,false,j,X,0,"not_data_DU","",ad,1,0,"",15,0,{});
f._98=new AN_StaticNetwork(98,false,j,X,0,"not_data_DU","",ad,1,0,"",8,0,{});
N.push(new CookieSyncTag(33,1,1,"https://sync.intentiq.com/profiles_engine/ProfilesEngineServlet?at=20&dpi=3&pcid=<VID><3RDPARTYIDS>",0));
N.push(new CookieSyncTag(53,2,1,"https://cm.g.doubleclick.net/pixel?google_nid=datonics-ddp&google_cm&google_sc&google_hm=<VID_E64>&google_redir=https%3A%2F%2Fpbid.pro-market.net%2Fengine%3Fdu%3D53%26mimetype%3Dimg",0));
N.push(new CookieSyncTag(73,3,1,"https://pixel-sync.sitescout.com/connectors/datonics/usersync?redir=https://pbid.pro-market.net/engine?du=73%26mimetype=img%26csync={userId}",0));
N.push(new CookieSyncTag(13,4,1,"https://secure.adnxs.com/getuid?https://pbid.pro-market.net/engine?du=13;csync=$UID;mimetype=img",0));
N.push(new CookieSyncTag(1,5,1,"https://match.adsrvr.org/track/cmf/generic?ttd_pid=9hr4p8g&ttd_tpi=1",0));
N.push(new CookieSyncTag(89,6,1,"https://idsync.rlcdn.com/400646.gif?partner_uid=<VID>",0));
N.push(new CookieSyncTag(98,8,1,"https://sync.sharethis.com/datonics?uid=<VID>",0));
N.push(new CookieSyncTag(85,9,1,"https://d.turn.com/r/dd/id/L2NzaWQvMS9jaWQvMjg0NTUxNTUvdC8w/url/https://pbid.pro-market.net/engine?du=85&mimetype=img&csync=$!{TURN_UUID}",0));
N.push(new CookieSyncTag(24,10,1,"https://um.simpli.fi/datonics",0));
N.push(new CookieSyncTag(81,11,1,"https://cms.analytics.yahoo.com/cms?partner_id=DATCS",0));
N.push(new CookieSyncTag(10,14,1,"https://ce.lijit.com/merge?pid=5067&3pid=<VID>&location=https%3A%2F%2Ffei.pro-market.net%2Fengine%3Fdu%3D10%26csync%3D%5BSOVRNID%5D%26site%3D158974%26size%3D1x1%26mimetype%3Dimg%26rnd%3D",0));
N.push(new CookieSyncTag(91,15,1,"https://aa.agkn.com/adscores/g.pixel?sid=9212294058&puid=<VID>&&bounced=1",0));
N.push(new CookieSyncTag(19,16,1,"https://bcp.crwdcntrl.net/map/c=14750/tp=DTNC/?https://pbid.pro-market.net/engine?mimetype=img&du=19&csync=${profile_id}",0));
N.push(new CookieSyncTag(67,17,1,"https://dpm.demdex.net/ibs:dpid=575&dpuuid=<VID>",0));
N.push(new CookieSyncTag(25,18,1,"https://sync.mathtag.com/sync/img?mt_exid=10019&redir=https%3A%2F%2Fpbid.pro-market.net%2Fengine%3Fdu%3D25%3Bcsync%3D%5BMM_UUID%5D%3Bmimetype%3Dimg",0));
N.push(new CookieSyncTag(88,19,1,"https://beacon.krxd.net/usermatch.gif?partner=datonics&partner_uid=<VID>",0));
var af={"119761":{"2":true,"14":true},"120697":{"1":true,"18":true,"20":true},"123961":{"1":true,"18":true,"20":true,"6":true,"9":true,"13":true},"123034":{"18":true,"20":true},"117631":{"17":true,"18":true,"69":true}};
this.CookieSyncCookieTag=function(ap,aq){this.dataUserId=ap;
this.lastSyncDate=aq
};
this.AN_Tag=function(aq,at,ap,au,ar){this.searchTerm=aq;
this.catID=at;
this.PPID=ap;
this.network=au;
this.date=ar
};
this.AN_CookieTag=function(aq,at,ap,ar,au){this.searchTerm=aq;
this.catID=at;
this.PPID=ap;
this.date=ar;
this.networkIds=String(au)
};
this.AN_NetTag=function(ap,aq,ar){this.tags=new Array();
this.network=null;
this.serialNum=ar;
this.catPriority=aq;
this.DuPriority=ap;
this.rank=0;
this.isCSync=false
};
this.updateReportCookie=function(at,ap,av,au){if(!e){SetCookie("anTD","",-1);
SetCookie("anTD","",-1,"pbid.pro-market.net");
SetCookie("anTD2","",-1);
SetCookie("anTD2","",-1,"pbid.pro-market.net");
SetCookie("anTD3","",-1);
SetCookie(h,"",-1);
return
}var ar=ReadCookie(h);
var aq="";
if(ar==""){ar="20141002|"+at+"."+ap+"."+av+"."+au+"."+G_PUBLISHER_ID
}else{ar=ar+"|"+at+"."+ap+"."+av+"."+au+"."+G_PUBLISHER_ID
}if(!(ar.length>R)){SetCookie(h,ar,90)
}};
this.sendCookieReport=function(){if(!e){SetCookie("anTD","",-1);
SetCookie("anTD","",-1,"pbid.pro-market.net");
SetCookie("anTD2","",-1);
SetCookie("anTD2","",-1,"pbid.pro-market.net");
SetCookie("anTD3","",-1);
SetCookie(h,"",-1);
return
}if(ao.ppType==i){var aq=document.createElement("img");
aq.width=1;
aq.height=1;
var ap=document.getElementsByTagName("body").item(0);
ap.appendChild(aq);
aq.src=x.replace("<PPID>",ao.profileProvider)+";rn="+randomNum()+";mds=0-"+c;
V=true;
++aj
}};
this.clearCompletedCategories=function(){try{if(!B||o){return
}var ap=ReadCookie(aa);
if(ap==""){return
}if(ap.charAt(ap.length-1)=="#"){ap=ap.substring(0,ap.length-1)
}var ay=ap.split(M);
var aA="";
for(var az=0;
az<ay.length;
az++){var aE=ay[az].split(A);
var aq=aE[1].substring(1,aE[1].length);
var ar=aE[2];
var at=aE[4].split(Q);
var au=aE[3];
var ax=findCategory(aq);
if(typeof(ax)!="undefined"){var av=ax.networks.split(",");
var aD=av.length;
for(var aw=0;
aw<av.length;
aw++){var aG=false;
var aF=true;
var aC=f[an+av[aw]];
if(aC.disabled){aD--;
aG=true
}if(aG==false){if(typeof(aC)!="undefined"){aF=aC.active
}if(isFilteredNetwork(ar,av[aw])||!aF){aD--
}else{if((aE[0]==undefined||aE[0]=="")&&(aC.dataType==ag||aC.dataType==Z)){aD--
}}}}if(aD>at.length||P>getSearchAgeInMinutes(au)){aA+=ay[az]+M
}}}if(aA.length>0){aA=aA.substring(0,aA.length-1)
}SetCookie(aa,aA,90)
}catch(aB){if(ac){alert(aB);
throw aB
}SetCookie(aa,"",90)
}};
this.networksIdsDiff=function(ay,az,aw){var ar=",";
for(var au=0;
au<aw.length;
au++){ar=ar+aw[au].networkIds+","
}var aA=new Array();
for(var au=0;
au<ay.length;
au++){var ap=ay[au];
var aB=false;
for(var at=0;
at<az.length;
at++){if(az[at]==ap){aB=true;
break
}}if(!aB){var aq=findNetwork(ap);
if(typeof(aq)=="undefined"){continue
}var ax=false;
var av=false;
if(aq.disabled!=true){av=true
}if((aq.dataType==ag||aq.dataType==Z)&&aq.active&&av){aA[aA.length]=ap
}else{if(aq.dataType==j){if(ar.indexOf(","+ap+",")!=-1){ax=true
}if(!ax&&aq.active&&av){aA[aA.length]=ap
}}}}}return aA
};
this.filterDuplicateTags=function(ar){var aq=new Object();
var au=new Array();
for(var at=0;
at<ar.length;
at++){var ap=ar[at];
if(ap.network.dataType==j){if(typeof(aq[ap.catID+an+ap.network.id])=="undefined"){au[au.length]=ap
}aq[ap.catID+an+ap.network.id]=true
}else{if(ap.network.dataType==ag){if(typeof(aq[ap.searchTerm+an+ap.network.id])=="undefined"){au[au.length]=ap
}aq[ap.searchTerm+an+ap.network.id]=true
}else{au[au.length]=ap
}}}return au
};
this.findTagsByCat=function(at,ap){var ar=new Array();
for(var aq=0;
aq<ap.length;
aq++){if(ap[aq].catID==at){ar[ar.length]=ap[aq]
}}return ar
};
this.getSentTermsFromCookieTags=function(aq){var ap=new Object();
for(var av=0;
av<aq.length;
av++){var at=aq[av].networkIds.split(Q);
for(var au=0;
au<at.length;
au++){var ar=findNetwork(at[au]);
if(typeof(ar)=="undefined"){continue
}if(ar.dataType==ag){ap[aq[av].searchTerm+an+ar.id]=true
}}}return ap
};
this.buildTagsInfo=function(av){var aD=new Array();
var aH=getSentTermsFromCookieTags(av);
for(var aF=0;
aF<av.length;
aF++){try{var az=av[aF];
var aq=az.catID;
var au=az.PPID;
var aG=az.date;
var aJ=getSearchAgeInMinutes(aG)/60;
var ay=findCategory(aq);
if(typeof(ay)=="undefined"){continue
}var aA=ay.networks.split(Q);
var aB=az.networkIds.split(Q);
var ap=findTagsByCat(aq,av);
markProspectNetworks(aA);
var ar=networksIdsDiff(aA,aB,ap);
for(var aC=0;
aC<ar.length;
aC++){var aK=findNetwork(ar[aC]);
if(typeof(aK)=="undefined"){continue
}if(I&&(aK.networkSecuredUrl==""||aK.networkSecuredUrl=="undefined")){continue
}var aI=false;
if(aK.disabled!=true){aI=true
}if(aK.active&&aI){if(au!=131911&&aK.maxTermsInURL>1&&aK.dataType!=2){var ax=expandedCategory(aq);
for(var at=0;
at<ax.length;
at++){ay=findCategory(ax[at]);
var aw=new AN_Tag(az.searchTerm,ax[at],az.PPID,aK,aG);
aD[aD.length]=aw
}}else{if(aK.maxTermsInURL>1&&aK.dataType==2){if(typeof(aH[az.searchTerm+an+aK.id])=="undefined"){var aL=new AN_Tag(az.searchTerm,aq,az.PPID,aK,aG);
aD[aD.length]=aL;
aH[az.searchTerm+an+aK.id]=true
}}else{var aL=new AN_Tag(az.searchTerm,aq,az.PPID,aK,aG);
aD[aD.length]=aL
}}}}}catch(aE){if(ac){alert(aE);
throw aE
}}}return filterDuplicateTags(aD)
};
this.getDataUserTag=function(ap,ar){for(var aq=0;
aq<ap.length;
aq++){if(ap[aq].dataUserId==ar){return ap[aq]
}}};
this.getProspectNetwork=function(aq){for(var ap=0;
ap<b.length;
ap++){if(b[ap].networkId==aq){return b[ap]
}}return null
};
this.markProspectNetworks=function(aq){var ap=null;
for(var ar=0;
ar<aq.length;
++ar){ap=getProspectNetwork(aq[ar]);
if(isDefined(ap)){ap.isProspect=true
}}};
this.getNeededCookieSyncTags=function(){var ap=new Array();
var av=false;
var ay=false;
if(typeof(G_VISITOR_ID)==="undefined"||G_VISITOR_ID=="0"){return ap
}var au=ReadCookie(T);
au=au.replace(an,"");
r=buildCSyncInfoFromCookie(au);
var aA=new Date().getTime();
var ar=24*60*60*1000;
var aq=null;
var at=null;
var ax=null;
var az=true;
for(var aw=0;
aw<N.length;
++aw){aq=N[aw];
at=getDataUserTag(r,aq.dataUserId);
ax=getProspectNetwork(aq.dataUserId);
az=isDefined(ax)?ax.isProspect:true;
ay=!(f[an+aq.dataUserId].disabled);
if(az&&ay){if(isDefined(at)){var aB=(aq.dataUserCSyncDays>0)?aq.dataUserCSyncDays:al;
if(aA>(parseInt(at.lastSyncDate)+aB*ar)){ap.push(aq)
}}else{ap.push(aq)
}}}return ap
};
this.buildNetTags=function(aF){var aD=new Array();
var ay=null;
var aq=null;
for(var aw=0;
aw<aF.length;
aw++){try{aq=aF[aw].network;
if(isFilteredNetwork(aF[aw].PPID,aq.id)){continue
}if((aF[aw].searchTerm==undefined||aF[aw].searchTerm=="")&&(aq.dataType==ag||aq.dataType==Z)){continue
}ay=findLastNetTag(aD,aq.id);
if(ay==null||ay.tags.length>=aq.maxTermsInURL){if(aq.maxTermsInURL==1){var aC=aF[aw].catID;
var au=findCategory(aC).segPriority
}else{au=null
}ay=new AN_NetTag(aq.priority,au,(ay==null?1:ay.serialNum+1));
aD.push(ay)
}ay.network=aF[aw].network;
ay.tags.push(aF[aw])
}catch(az){if(ac){alert(az)
}}}var at=0;
var ap=0;
while(at<aD.length){if(aD[ap].tags.length==1){if(aD[ap].rank==0){var ar=new Array();
var av=new Array();
for(var aA=ap;
aA<aD.length;
aA++){if(aD[ap].network.id==aD[aA].network.id){ar[ar.length]=aD[aA];
av[av.length]=aA
}}ar.sort(sortTagBySegPriority);
var ax=0;
for(var aB=0;
aB<ar.length;
aB++){ax++;
ar[aB].serialNum=ax;
var aE=av[aB];
aD[aE]=ar[aB];
aD[aE].rank=calcNetTagRank(aD[aE]);
at++
}ap++
}else{ap++
}}else{aD[ap].rank=calcNetTagRank(aD[ap]);
at++;
ap++
}}return aD
};
this.mergeDusTagsArray=function(){var ar=0;
var ap=0;
var aq=U.length+l.length;
p=new Array();
for(var at=0;
at<aq;
at++){if(ap<U.length&&ar<l.length){if(U[ap].DuPriority<l[ar].DuPriority){p.push(U[ap]);
ap++
}else{p.push(l[ar]);
ar++
}}else{if(ap<U.length){p.push(U[ap]);
ap++
}else{p.push(l[ar]);
ar++
}}}};
this.findLastNetTag=function(ar,aq){for(var ap=ar.length-1;
ap>=0;
ap--){if(ar[ap].network.id==aq){return ar[ap]
}}return null
};
this.addCurrentSearch=function(ay){var ap=(new Date()).getTime();
var aB=false;
if(G_NEW_DATA.length<=0){return
}for(var aw=0;
aw<G_NEW_DATA.length;
++aw){var aA=G_NEW_DATA[aw][0];
var aq=G_NEW_DATA[aw][1];
for(var at=0;
at<aq.length;
++at){var au=aq[at][0];
var au=encode(au);
var az=aq[at][1];
for(var av=0;
av<az.length;
av++){if(az[av]<=0){continue
}aB=false;
for(var ar=0;
ar<ay.length;
ar++){var ax=ay[ar];
if(az[av]==ax.catID&&au==ax.searchTerm){ax.date=ap;
ax.PPID=aA;
aB=true;
break
}}if(!aB){ay.push(new AN_CookieTag(au,az[av],aA,ap,""))
}}}}};
this.buildCSyncInfoFromCookie=function(aw){var aq=new Array();
if(aw==""||aw.length<1){return aq
}var av=aw.split(M);
for(var at=0;
at<av.length;
at++){if(av[at].length<1){continue
}var ap=av[at].split(A);
var au=ap[0];
var ar=ap[1];
aq.push(new CookieSyncCookieTag(au,ar))
}return aq
};
this.buildTagsFromCookie=function(aq){var aw=new Array();
if(aq!=""&&aq.length>5){var aA=aq.split((M));
for(var av=0;
av<aA.length;
av++){if(aA[av]!=""&&aA[av].length>5){var ay=aA[av].split(A);
var ax=ay[0];
var ar=ay[1].substring(1,ay[1].length);
var az=ay[2];
var au=ay[3];
var at=ay[4];
var ap=findCategory(ar);
if(typeof(ap)=="undefined"){continue
}if(ap.expireDate*24*60>getSearchAgeInMinutes(au)){aw[aw.length]=new AN_CookieTag(ax,ar,az,au,at)
}}}}return aw
};
this.findNetwork=function(ap){return f[an+ap]
};
this.findCategory=function(ap){return O[an+ap]
};
this.getSearchAgeInMinutes=function(ap){var aq=new Date();
return Number((aq.getTime()-Number(ap))/(1000*60))
};
this.isContainsStr=function(at,ar){var aq=false;
for(var ap=0;
ap<ar.length;
ap++){if(ar[ap]==at){aq=true
}}return aq
};
this.sumDistSlots=function(ap){c=0;
for(var aq=0;
aq<ap.length;
aq++){c+=1;
if(ap[aq].isCSync==false){c+=ap[aq].network.externalRedirects
}}V=false;
return
};
this.expandedCategory=function(aq){var at=new Array();
at.push(aq);
var ar=findCategory(aq).parentId;
var ap=0;
while(ap<3&&ar!=undefined&&ar!=""&&ar!=999999){ap++;
at.push(ar);
ar=findCategory(ar).parentId
}return at
};
this.encode=function(au,ar){var aq="";
var at=null;
for(var ap=0;
ap<au.length;
++ap){at=w.indexOf(au.charAt(ap));
aq+=w.charAt((at+Math.pow(ap+1,3))%w.length)
}return aq
};
this.decode=function(au,at){var aq="";
var ar=null;
for(var ap=0;
ap<au.length;
ap++){ar=w.indexOf(au.charAt(ap));
ar=(ar-(Math.pow(ap+1,3)%w.length))%w.length;
aq+=w.charAt(ar>=0?ar:w.length+ar)
}return aq
};
this.sortNetTagsByRank=function(aq,ap){return aq.rank-ap.rank
};
this.sortTagBySegPriority=function(aq,ap){return aq.catPriority-ap.catPriority
};
this.SetCookie=function(aw,av,au,ap){if(!B||aw==aa){return
}var ar=new Date();
var aq=new Date();
if(au==null||au==0){au=1
}aq.setTime(ar.getTime()+3600000*24*au);
if(typeof(ap)=="undefined"||ap==""){ap=J
}var at;
if(av!=""){at=aw+"="+escape(av)+"; Expires="+aq.toGMTString()+"; Domain="+ap+";"
}else{at=aw+"=x; Expires="+aq.toGMTString()+"; Domain="+ap+";"
}if(browser.chrome===true){at+=" SameSite=None;Secure;"
}document.cookie=at
};
this.ReadCookie=function(au){if(!B){return""
}var ar=""+document.cookie;
var at=ar.indexOf(au);
if(at==-1||au==""){return""
}var ap=ar.indexOf(";",at);
if(ap==-1){ap=ar.length
}var aq=unescape(ar.substring(at+au.length+1,ap));
if(aq=="x"){return""
}else{return aq
}};
this.anCatToNetworkCat=function(aq,ap){var au=f[an+aq];
var at=au.DuCatIdType;
if(at==D){return ap+""
}var ar=au.anCategoriesToNetworkCategories[ap];
if(at==L){if(ar!=null&&ar!=""){return ar+""
}else{return ap+""
}}if(at==X){if(ar!=null){return ar+""
}else{return""
}}return""
};
this.calcNetTagRank=function(ap){return ap.network.priority+ap.serialNum*100
};
this.isPageLoad=function(){if(browser.msie||browser.opera||browser.chrome){return(document.readyState==4||document.readyState=="complete")
}else{if(browser.mozilla||browser.safari){return u
}}};
this.isSecuredPage=function(){var ap=window.location.href;
return ap.indexOf("https://")>-1?true:false
};
this.findCookieTag=function(au,aq,av){var at=null;
for(var ar=0;
ar<av.length;
ar++){var ap=av[ar];
if(typeof(ap)!="undefined"){if(ap.searchTerm==aq&&ap.catID==au){at=ap;
break
}}}return at
};
this.updateCookieCSyncData=function(ar){if(!B){return""
}var av=null;
var at=null;
var au=new Date().getTime();
for(var aq=0;
aq<ar.length;
aq++){at=ar[aq].dataUserId;
av=getDataUserTag(r,at);
if(isDefined(av)){av.lastSyncDate=au
}else{r.push(new CookieSyncCookieTag(at,au))
}}var ap="";
for(var aq=0;
aq<r.length;
aq++){ap+=cSyncToCookieStr(r[aq]);
ap+=M
}SetCookie(T,ap.replace(an,""),W)
};
this.updateCookieNetData=function(aw,av){if(!B){return""
}var ar=null;
var ap=null;
for(var at=0;
at<av.length;
at++){ar=av[at];
for(var aq=0;
aq<ar.tags.length;
aq++){ap=ar.tags[aq];
var au=findCookieTag(ap.catID,ap.searchTerm,aw);
if(au!=null){au.networkIds+=(au.networkIds==""?"":Q)+ar.network.id
}else{if(ac){alert("netTag not in cookie: "+ap.searchTerm+", "+ap.catID)
}}}}setCookieData(aw)
};
this.setCookieData=function(aq){var ap=cookieTagsToStr(aq);
if(ap.length>R){aq=removeOldTags(aq);
ap=cookieTagsToStr(aq)
}SetCookie(aa,ap,90)
};
this.removeOldTags=function(at){var aq=new Array();
at=at.sort(sortByDate);
var ap=K;
for(var ar=0;
ar<at.length;
ar++){if(ar>ap){aq[aq.length]=at[ar]
}}return aq
};
this.sortByDate=function(aq,ap){return aq.date-ap.date
};
this.cookieTagsToStr=function(ar){var ap="";
for(var aq=0;
aq<ar.length;
aq++){ap=ap+tagToCookieStr(ar[aq])+M
}ap=ap.substring(0,ap.length-1);
return ap
};
this.tagToCookieStr=function(ap){var aq=ap.searchTerm+A+an+ap.catID+A+ap.PPID+A+ap.date+A+ap.networkIds;
return aq
};
this.cSyncToCookieStr=function(aq){var ap=aq.dataUserId+A+aq.lastSyncDate;
return ap
};
this.sendCSyncTag=function(at){var ap=at.dataUserSecuredUrl;
var aq;
var ar="";
if(typeof(G_VISITOR_ID)!=="undefined"&&G_VISITOR_ID!="0"){ap=ap.replace(am,G_VISITOR_ID);
if(typeof(G_VISITOR_ID_E64)!=="undefined"&&G_VISITOR_ID_E64!=""){ap=ap.replace(t,G_VISITOR_ID_E64)
}}else{if(at.dataUserId==33){ap=ap.replace(am,"").replace(/&pcid=/g,"")
}}if(at.dataUserId==33&&typeof(G_IIQ_3RD)!="undefined"&&G_IIQ_3RD!=""){ap=ap.replace(ai,G_IIQ_3RD)
}else{ap=ap.replace(ai,"")
}aq=at.tagType;
sendUrl(ap,aq);
updateReportCookie(at.dataUserId,ao.profileProvider,v,ar)
};
this.sendNetTagToPartner=function(aC){var at=aC.network;
var aA=new Array();
var ar=new Array();
var aB=new Array();
var aG=null;
var az=null;
var aD=(at.dataType==j||at.dataType==Z);
var ay=(at.dataType==ag||at.dataType==Z);
for(var ax=0;
ax<aC.tags.length&&ax<at.maxTermsInURL;
ax++){az=aC.tags[ax];
if(aD){aG=anCatToNetworkCat(at.id,az.catID);
if(aG!=""){var aq=isContainsStr(aG,ar);
if(!aq){ar.push(aG)
}}else{continue
}}if(ay){var aE=isContainsStr(az.searchTerm,aB);
if(!aE){aB.push(az.searchTerm)
}}aA.push(az)
}if(ay){for(var ax=0;
ax<aB.length;
ax++){aB[ax]=decode(aB[ax])
}}var aw;
if(I){aw=at.networkSecuredUrl
}else{aw=at.networkUrl
}var aF;
if(aD){var av="";
if(at.id==9){av=chainWithDelim(ar,at.termDelimiter);
av=av+"}"
}else{if(at.id==84){av=chainWithDelim(ar,at.termDelimiter)
}else{av=chainWithDelim(ar,encodeURIComponent(at.termDelimiter))
}}aF=new RegExp(s,"gi");
aw=aw.replace(aF,av)
}if(ay){var au=chainWithDelim(aB,encodeURIComponent(at.termDelimiter));
aF=new RegExp(ae,"gi");
aw=aw.replace(aF,au)
}aF=new RegExp(ab,"gi");
var ap;
if(I){ap="https://"+aw.replace(aF,randomNum())
}else{ap="http://"+aw.replace(aF,randomNum())
}if(typeof(G_VISITOR_ID)!=="undefined"&&G_VISITOR_ID!="0"){ap=ap.replace(am,G_VISITOR_ID);
if(typeof(G_VISITOR_ID_E64)!=="undefined"&&G_VISITOR_ID_E64!=""){ap=ap.replace(t,G_VISITOR_ID_E64)
}}else{if(aC.network.id==33){ap=ap.replace(am,"").replace(/&pcid=/g,"")
}}if(aC.network.id==33&&typeof(G_IIQ_3RD)!="undefined"&&G_IIQ_3RD!=""){ap=ap.replace(ai,G_IIQ_3RD)
}else{ap=ap.replace(ai,"")
}sendUrl(ap,at.htmlType);
for(var ax=0;
ax<aA.length;
ax++){updateReportCookie(aA[ax].network.id,aA[ax].PPID,aA[ax].catID,aA[ax].searchTerm)
}};
this.chainWithDelim=function(at,aq){var ap="";
for(var ar=0;
ar<at.length;
ar++){ap+=at[ar]+(ar+1==at.length?"":aq)
}return ap
};
this.randomNum=function(){return Math.floor(Math.random()*1000000000+1)
};
this.isDefined=function(ap){return(typeof ap!=="undefined"&&ap!=null)
};
this.sendUrl=function(aq,at){var ap=document.getElementsByTagName("body").item(0);
if(document.createElement!=undefined&&ap!=undefined&&ap.appendChild!=undefined){switch(at){case ad:element=document.createElement("img");
element.width=1;
element.height=1;
break;
case Y:element=document.createElement("iframe");
element.width=0;
element.height=0;
element.scrolling="no";
element.marginWidth=0;
element.marginHeight=0;
element.frameBorder=0;
break;
case z:element=document.createElement("script");
element.type="text/javascript";
break
}ap.appendChild(element);
element.src=aq
}else{var ar="";
switch(at){case ad:ar="<img id='AN_IMAGE_ID' src='"+aq+"' WIDTH='1' HEIGHT='1' BORDER=0/> \n";
break;
case Y:ar="<IFRAME id='AN_IFREAM_ID' WIDTH='1' HEIGHT='1' MARGINWIDTH='0' MARGINHEIGHT='0' HSPACE='0' VSPACE='0' FRAMEBORDER='0' SCROLLING='no' src='"+aq+"' ></IFRAME> \n";
break;
case z:ar="<script id='AN_SCRIPT_ID' src='"+aq+"'><\/script> \n";
break
}document.write(ar)
}};
this.updatePageStatus=function(){u=true
};
this.isFilteredNetwork=function(aw,ar){if(typeof(af)!="undefined"){var aq=false,au=false,ap,av;
for(var at=0;
at<2;
at++){ap=af[aw];
if(typeof(ap)!="undefined"){av=ap[ar];
if(typeof(av)!="undefined"){aq=true
}}au=au||aq;
aq=false;
if(aw!=ao.profileProvider){aw=ao.profileProvider
}else{break
}}return au
}else{return false
}};
return{anTaggingProcessInit:function(){B=(navigator.cookieEnabled)?true:false;
I=isSecuredPage();
if(typeof navigator.cookieEnabled=="undefined"&&!B){document.cookie="testcookie";
B=(document.cookie.indexOf("testcookie")!=-1)?true:false
}if(document.addEventListener){document.addEventListener("DOMContentLoaded",updatePageStatus,false)
}if(typeof(G_NEW_DATA)==="undefined"){G_NEW_DATA=new Array()
}if(typeof(G_PUBLISHER_ID)==="undefined"){G_PUBLISHER_ID=0
}if(typeof(G_VISITOR_ID)==="undefined"){G_VISITOR_ID=="0"
}if(typeof(G_DU_DIS)=="undefined"){G_DU_DIS=""
}if(typeof(m[an+G_PUBLISHER_ID])==="undefined"){m[an+G_PUBLISHER_ID]=new AN_StaticPP(G_PUBLISHER_ID,i,8,false,0,0,0)
}ao=m[an+G_PUBLISHER_ID];
o=AN_TAG_LIB.checkOptout();
if(o==true){return
}if(typeof(G_DU_DIS)!="undefined"&&G_DU_DIS!=""){var ap=G_DU_DIS.split(Q);
for(var ar=0;
ar<ap.length;
ar++){var aq=f[an+ap[ar]];
if(typeof(aq)!="undefined"){aq.disabled=true
}}}if(isDefined(b)&&b.length>0){for(var ar=0;
ar<b.length;
++ar){var aq=f[an+b[ar].networkId];
if(isDefined(aq)){aq.active=false
}}}clearCompletedCategories();
if(true){AN_TAG_LIB.startTagingProcess(false)
}},ReadCookie2:function(au){if(!B){return""
}var ar=""+document.cookie;
var at=ar.indexOf(au);
if(at==-1||au==""){return""
}var ap=ar.indexOf(";",at);
if(ap==-1){ap=ar.length
}var aq=unescape(ar.substring(at+au.length+1,ap));
if(aq=="x"){return""
}else{return aq
}},checkOptout:function(){var ap=AN_TAG_LIB.ReadCookie2(n);
return(typeof ap!=="undefined"&&ap!=null&&ap!="")
},backGroundRedirect:function(){var aq=0;
var au=false;
var av=0;
var at;
if(typeof l==="undefined"||typeof U==="undefined"||typeof p==="undefined"){return
}if(ao.isGroupRedirect){k=buildTagsInfo(ak);
U=buildNetTags(k);
U.sort(sortNetTagsByRank);
l=getNeededCookieSyncTags();
mergeDusTagsArray();
var ar=0;
while(!au&&ar<p.length){at=p[ar];
av=1;
if(at.isCSync!=true){av+=at.network.externalRedirects
}aq=(ao.isGroupRedirect?d:y)+av;
if(aq>ao.backGroundeMaxredirect){++ar
}else{au=true;
F=ar
}}}else{while(!au&&F<p.length){at=p[F];
av=1;
if(at.isCSync!=true){av+=at.network.externalRedirects
}aq=(ao.isGroupRedirect?d:y)+av;
if(aq>ao.backGroundeMaxredirect){++F
}else{au=true
}}}if(ao.isBackGroundRedirect&&au){y+=av;
d+=av;
if(d>=ao.backGroundeMaxredirect){d=0
}AN_TAG_LIB.startTagingProcess(true)
}else{var ap=false;
if(ao.isGroupRedirect){ap=(F>=p.length&&d!=0)
}else{ap=(F>=p.length||y>ao.backGroundeMaxredirect)
}if(ap){sendCookieReport()
}}},startTagingProcess:function(aD){if(!isPageLoad()){setTimeout("AN_TAG_LIB.startTagingProcess("+aD+")",50);
return
}var av=ao;
var au="";
if(!G){if(B){if(!o){au=ReadCookie(aa);
ak=buildTagsFromCookie(au)
}}else{ak=new Array()
}addCurrentSearch(ak);
k=buildTagsInfo(ak);
if(B){l=getNeededCookieSyncTags()
}else{l=new Array()
}U=buildNetTags(k);
G=true
}if(k.length==0&&U.length==0&&l.length==0){av.isBackGroundRedirect=false;
return
}var ax="";
var ap=new Array();
var az=new Array();
U=U.sort(sortNetTagsByRank);
mergeDusTagsArray();
if(!ao.isGroupRedirect){if(c==0||V){sumDistSlots(p)
}}else{if(!aD){sumDistSlots(p)
}}if(!aD){G_processStarted=true;
var aA=0;
var aw=0;
var ar;
if(typeof(G_PRE_TAGS)!="undefined"&&!g){aA=G_PRE_TAGS;
y=G_PRE_TAGS;
g=true
}for(var at=0;
aA<av.maxTags&&at<p.length;
at++){var aq=p[at];
var aB=aq.isCSync;
if(aB){sendCSyncTag(aq);
az.push(aq);
--c;
++aA
}else{aw=1+aq.network.externalRedirects;
ar=aw+aA;
if(ar>av.maxTags){continue
}sendNetTagToPartner(aq);
ap.push(aq);
c=c-aw;
aA=ar
}}F=at;
updateCookieCSyncData(az);
if(!o){updateCookieNetData(ak,ap)
}}else{if(F<p.length){var ay=p[F];
if(ay.isCSync==true){sendCSyncTag(ay);
az.push(ay);
++F;
--c
}else{sendNetTagToPartner(ay);
ap.push(ay);
c=c-1-ay.network.externalRedirects;
F++
}}updateCookieCSyncData(az);
if(!o){updateCookieNetData(ak,ap)
}}var aC=null;
if(av.isGroupRedirect&&d==0&&ap.length>0){sendCookieReport()
}if(!av.isGroupRedirect||(aD&&d!=0)){aC=(av.backGroundedirectInterval>0)?av.backGroundedirectInterval:0
}else{aC=av.groupRedirectInterval
}if(typeof(aC)!="undefined"&&aC!=null){setTimeout("AN_TAG_LIB.backGroundRedirect()",aC)
}else{return
}}}
}();
AN_TAG_LIB.anTaggingProcessInit()
}catch(err){};