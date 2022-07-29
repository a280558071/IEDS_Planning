clc;
clear all;
%% 输入园区历史负荷曲线(这一部分有修�?)
load('dayInput.mat','day01','day02','day03','day04','day05','day06','day07','day08');
C=[day01',day02',day03',day04',day05',day06',day07',day08'];
Load_E=C(1,:);
Load_C=C(2,:);
Load_H=C(3,:);
k_number=8;      %典型日个数，取�?�为8
Load_scene=24*k_number;     %三个典型日，�?个典型日24小时%�?192: x1*24
Proportion_typicalday=[65/365;26/365;66/365;26/365;65/365;26/365;65/365;26/365];     %5:2:5:2:5:2:5:2
%% 历史电价（电价直接只用这�?套）
Price_electricity_day=[
    0.3818
    0.3818
    0.3818
    0.3818
    0.3818
    0.3818
    0.3818
    0.8395
    0.8395
    0.8395
    1.3222
    1.3222
    1.3222
    1.3222
    1.3222
    0.8395
    0.8395
    0.8395
    1.3222
    1.3222
    1.3222
    0.8395
    0.8395
    0.3818];
%% 设备参数（为了方便设备输入参数修改，�?有转化效率设置成变量�?
Price_gas=3.3;  %燃气价格�?2.5�?/立方�?
Planning_years=10;
CCHP_types=6;
GB_types=10;
AC_types=32;
EB_types=20;
SUB_types=30;

n_SUB=1;

n_E_Min=0.35;
n_E_Max=0.4;
n_E=n_E_Min:(n_E_Max-n_E_Min)/(CCHP_types-1):n_E_Max; %cchp产电效率

n_H_Min=0.4;
n_H_Max=0.45;
n_H=n_H_Min:(n_H_Max-n_H_Min)/(CCHP_types-1):n_H_Max; %cchp产热效率
COP_C=1.2;  %CCHP余热制热和制冷的效率
COP_H=0.9;
n_GB=0.8;
COP_AC=2.5; % 空调以电换冷的效率，coefficient of power
n_EB_Min=0.9;
n_EB_Max=0.95;
n_EB=n_EB_Min:(n_EB_Max-n_EB_Min)/(EB_types-1):n_EB_Max;
LHV=35.544/3.6; %LHV单位为kW*h/m3—�?�低位燃料热�?32.967 MJ/m3，一度电等于3.6MJ，除�?3.6表示折算为kW*h/m3
%% 构建能量耦合矩阵
Converter_SUB=repmat([n_SUB;0;0],1,SUB_types);
Converter_CCHP=[n_E;n_H*COP_C;n_H*COP_H];
Converter_GB=repmat([0;0;n_GB],1,GB_types);
Converter_AC=repmat([0;COP_AC;0],1,AC_types);
Converter_EB=[zeros(1,EB_types);zeros(1,EB_types);n_EB];
C_matrix=[Converter_SUB,Converter_CCHP,Converter_GB,Converter_AC,Converter_EB];
%% 建设方案成本
CCHP_capacity_min=800;%千瓦�?6档，�?�?600kw
CCHP_capacity_max=3800;%3800
CCHP_capacity=CCHP_capacity_min:((CCHP_capacity_max-CCHP_capacity_min)/(CCHP_types-1)):CCHP_capacity_max;%折算到电负荷
CCHP_cost=CCHP_capacity*300;%2500   %按单位�?�价 7560万元/MW天然气计算（差不�?200块钱�?千瓦的燃气热供应，�?�虑多能供应，大概乘�?3�?

GB_capacity_min=500;%十档，一�?500kw
GB_capacity_max=5000;
GB_capacity=GB_capacity_min:((GB_capacity_max-GB_capacity_min)/(GB_types-1)):GB_capacity_max;%折算到热负荷
GB_cost=GB_capacity*70;%40  %锅炉建设成本，单位�?�价 40万元/MW,40

AC_capacity_min=500;%制冷量，32档，�?�?500kw
AC_capacity_max=16000;%100
AC_capacity=(AC_capacity_min:((AC_capacity_max-AC_capacity_min)/(AC_types-1)):AC_capacity_max)/COP_AC;  %折算到电消�???
AC_cost=AC_capacity*COP_AC*870;  %电制冷空调成本，单位造价 43万元 /MW冷负�?,*COP_AC（一匹即2.3kw制冷量差不多2000�?(2000/2.3)单位是元

EB_capacity_min=250;%2�?6档，�?�?
EB_capacity_max=5000;%32
EB_capacity=EB_capacity_min:((EB_capacity_max-EB_capacity_min)/(EB_types-1)):EB_capacity_max;%折算到电消�??
EB_cost=EB_capacity*55;%10千瓦的成�?3000左右

SUB_capacity_min=500;
SUB_capacity_max=15000;
SUB_capacity=(SUB_capacity_min:((SUB_capacity_max-SUB_capacity_min)/(SUB_types-1)):SUB_capacity_max);
SUB_cost=SUB_capacity*4;%两万千伏安的是八万块左右，一千伏安就�?4块钱左右？，单位是元
%% 模型变量声明
%0-1机组建设决策变量
X_CCHP=binvar(1,CCHP_types,'full');
X_GB=binvar(1,GB_types,'full');
X_AC=binvar(1,AC_types,'full');
X_EB=binvar(1,EB_types,'full');
X_SUB=binvar(1,SUB_types,'full');
%机组耗电耗气连续变量
P_CCHP_gas=sdpvar(Load_scene,CCHP_types,'full');    %CCHP单位时间内所用燃气热值，单位是MW（应该修改成kw比较合�?�）
V_CCHP_gas=sdpvar(Load_scene,CCHP_types,'full');    %CCHP单位时间内所用燃气量，单位是m3/h
P_SUB_electricity=sdpvar(Load_scene,SUB_types,'full');      %变电站出力，单位是MW
P_GB_gas=sdpvar(Load_scene,GB_types,'full');        %GB单位时间内所用燃气热值，单位是MW
V_GB_gas=sdpvar(Load_scene,GB_types,'full');        %GB单位时间内所用燃气量，单位是m3/h
P_AC_electricity=sdpvar(Load_scene,AC_types,'full'); %中央空调输入电出力，单位MW
P_EB_electricity=sdpvar(Load_scene,EB_types,'full');%电锅炉输入电能，单位MW
%%
Constraints=[];
%%
Cons_PL=[];
P=sdpvar(SUB_types+CCHP_types+GB_types+AC_types+EB_types,Load_scene,'full');
for t=1:Load_scene
    Cons_PL=[ Cons_PL,P(:,t)==[P_SUB_electricity(t,:)';P_CCHP_gas(t,:)';P_GB_gas(t,:)';P_AC_electricity(t,:)';P_EB_electricity(t,:)']];%注意这里是等�?==
end

L=sdpvar(3,Load_scene,'full');
for t=1:Load_scene
    Cons_PL=[Cons_PL,L(:,t)==[Load_E(t)+sum(P_AC_electricity(t,:),2)+sum(P_EB_electricity(t,:),2);Load_C(t);Load_H(t)]];
end
Constraints=[Constraints,Cons_PL];
%% 负荷平�
Cons_loadbalance=[];
for t=1:Load_scene
    Cons_loadbalance=[Cons_loadbalance,L(1,t)==C_matrix(1,:)*P(:,t)];
    Cons_loadbalance=[Cons_loadbalance,L(2,t)<=C_matrix(2,:)*P(:,t)];
    Cons_loadbalance=[Cons_loadbalance,L(3,t)<=C_matrix(3,:)*P(:,t)];
end
Constraints=[Constraints,Cons_loadbalance];
%% CCHP建模
Cons_CCHP=[];
for i=1:CCHP_types
    Cons_CCHP=[Cons_CCHP,0<=P_CCHP_gas(:,i)*n_E(i)<=CCHP_capacity(i)*X_CCHP(i)];%/n_E(i) CCHP出力上下�?,可以将数组与数�?�进行比较，得到的是逻辑�?0/1
end
Cons_CCHP=[Cons_CCHP,P_CCHP_gas==V_CCHP_gas*LHV];  % V_CCHP_gas单位为m3/h, LHV单位为kW.h/m3，P_CCHP_gas单位为MW(不除�?1000，就是kw的单�?)
Cons_CCHP=[Cons_CCHP,sum(X_CCHP)<=1];
Constraints=[Constraints,Cons_CCHP];
%% GB建模
Cons_GB=[];
for j=1:GB_types
    Cons_GB=[Cons_GB,0<=P_GB_gas(:,j)<=GB_capacity(j)*X_GB(j)/n_GB];
end
Cons_GB=[Cons_GB,P_GB_gas==V_GB_gas*LHV];
Cons_GB=[Cons_GB,sum(X_GB)<=1];
Constraints=[Constraints,Cons_GB];
%% AC建模
Cons_AC=[];
for k=1:AC_types
    Cons_AC=[Cons_AC,0<=P_AC_electricity(:,k)<=AC_capacity(k)*X_AC(k)];
end
Cons_AC=[Cons_AC,sum(X_AC)<=1];
Constraints=[Constraints,Cons_AC];
%% EB建模
Cons_EB=[];
for n=1:EB_types
    Cons_EB=[Cons_EB,0<=P_EB_electricity(:,n)<=EB_capacity(n)*X_EB(n)];
end
Cons_EB=[Cons_EB,sum(X_EB)<=1];
Constraints=[Constraints,Cons_EB];
%% SUB建模
Cons_SUB=[];
for m=1:SUB_types
    Cons_SUB=[Cons_SUB,0<=P_SUB_electricity(:,m)<=SUB_capacity(m)*X_SUB(m)];%考虑裕度�?20%。�?�虑以后会改变输入功率，但是不影响�?�型，应该是建设成本参数设置问题
end
Cons_SUB=[Cons_SUB,sum(X_SUB)<=1];
Constraints=[Constraints,Cons_SUB];
%% 建设成本年�??
Obj_bulding_CCHP=sum(CCHP_cost.*X_CCHP,2);
Obj_bulding_GB=sum(GB_cost.*X_GB,2);
Obj_bulding_AC=sum(AC_cost.*X_AC,2);
Obj_bulding_EB=sum(EB_cost.*X_EB,2);
Obj_bulding_SUB=sum(SUB_cost.*X_SUB,2);
r=0.07;
U=(r*(1+r)^Planning_years)/((1+r)^Planning_years-1);
Obj_inv=U*(Obj_bulding_CCHP+Obj_bulding_GB+Obj_bulding_AC+Obj_bulding_EB+Obj_bulding_SUB);%U*
%% 年运行成�?
Proportion_typicalday_rep=repmat(Proportion_typicalday,1,24);
Proportion_typicalday_reshape=reshape(Proportion_typicalday_rep',1,[]);
Proportion_typicalday_CCHP=repmat(Proportion_typicalday_reshape',1,CCHP_types);
Proportion_typicalday_GB=repmat(Proportion_typicalday_reshape',1,GB_types);
Proportion_typicalday_SUB=repmat(Proportion_typicalday_reshape',1,SUB_types);
Proportion_typicalday_AC=repmat(Proportion_typicalday_reshape',1,AC_types);
Proportion_typicalday_EB=repmat(Proportion_typicalday_reshape',1,EB_types);

Price_electricity_typicalday=repmat(Price_electricity_day,k_number,1);%3是典型日的数�?

Price_electricity_SUB=repmat(Price_electricity_typicalday,1,SUB_types);
Price_electricity_AC=repmat(Price_electricity_typicalday,1,AC_types);
Price_electricity_EB=repmat(Price_electricity_typicalday,1,EB_types);

Obj_operation_CCHP=365*Price_gas*sum(sum(Proportion_typicalday_CCHP.*V_CCHP_gas));
Obj_operation_GB=365*Price_gas*sum(sum(Proportion_typicalday_GB.*V_GB_gas));
Obj_operation_SUB=365*sum(sum(Price_electricity_SUB.*Proportion_typicalday_SUB.*P_SUB_electricity));
Obj_operation_AC=365*sum(sum(Price_electricity_AC.*Proportion_typicalday_AC.*P_AC_electricity));
Obj_operation_EB=365*sum(sum(Price_electricity_EB.*Proportion_typicalday_EB.*P_EB_electricity));
Obj_ope=Obj_operation_CCHP+Obj_operation_GB+Obj_operation_SUB;
Obj=Obj_inv+Obj_ope;
%% 问题求解
ops=sdpsettings('solver','gurobi','verbose',2);
optimize(Constraints,Obj,ops);
value(Obj_inv)
value(Obj_ope)
value(Obj)
%% 画图展示
S_X_CCHP=value(X_CCHP);
S_X_GB=value(X_GB);
S_X_AC=value(X_AC);
S_X_EB=value(X_EB);
S_X_SUB=value(X_SUB);
S_P_CCHP_gas=value(P_CCHP_gas);
S_V_CCHP_gas=value(V_CCHP_gas);
S_P_SUB_electricity=value(P_SUB_electricity);
S_P_GB_gas=value(P_GB_gas);
S_V_GB_gas=value(V_GB_gas);
S_P_AC_electricity=value(P_AC_electricity);
S_P_EB_electricity=value(P_EB_electricity);
S_P=value(P);
S_L=value(L);

S1_X_CCHP=find(S_X_CCHP);%找到建设方案
S1_X_GB=find(S_X_GB);
S1_X_AC=find(S_X_AC);
S1_X_EB=find(S_X_EB);
S1_X_SUB=find(S_X_SUB);

CCHP_building=sum(S_X_CCHP.*CCHP_capacity(1,:),2);
GB_building=sum(S_X_GB.*GB_capacity(1,:),2);
AC_building=sum(S_X_AC.*AC_capacity(1,:),2);
EB_building=sum(S_X_EB.*EB_capacity(1,:),2);
SUB_building=sum(S_X_SUB.*SUB_capacity(1,:),2);%设备建设容量

CCHP_building_cost=value(Obj_bulding_CCHP);
GB_building_cost=value(Obj_bulding_GB);
AC_building_cost=value(Obj_bulding_AC);
EB_building_cost=value(Obj_bulding_EB);
SUB_building_cost=value(Obj_bulding_SUB);
building_cost=value(Obj_inv);

operation_CCHP_cost=value(Obj_operation_CCHP);
operation_GB_cost=value(Obj_operation_GB);
operation_SUB_cost=value(Obj_operation_SUB);
operation_AC_cost=value(Obj_operation_AC);
operation_EB_cost=value(Obj_operation_EB);
Obj_operation_cost=value(Obj_ope);