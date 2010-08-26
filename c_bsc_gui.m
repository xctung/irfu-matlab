function c_bsc_gui(varargin)
%C_BSC_GUI STAFF B GUI
%
% This program is to help getting STAFF-SC B data
%
% $Id$

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

persistent h0;
%persistent inprog_mtx; % this is a kinda mutex to hold "in progress" status

main_fig_id = 28;

if nargin, action = varargin{1};
else action = 'init';
end

if regexp(action,'^click_[X-Z]axes$')
    curr_ax = action(7);
	action = 'click_axes';
end

if regexp(action,'^select_c[1-4]$')
    curr_sc = str2double(action(9));
	action = 'update_sc';
end

switch action
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'init'
        %inprog_mtx = 0;
        
        % Create figure
        h0 = figure(main_fig_id);
        clf
        set(main_fig_id,'Name', 'CLUSTER B-SA GUI')
        
        hnd = guihandles(h0);
        
        hnd.BSCData = [];
        hnd.BSCDataAppend = [];
        hnd.diB = [];
        hnd.diBSC = [];
        hnd.pha = [];
        hnd.ts_marker = [];
        hnd.cl_id = [];
        
        %Load data
        for cl_id = 1:4
            [ok, data] = c_load('wBSC?',cl_id);
            if ok && ~isempty(data)
                hnd.BSCData = data;
                hnd.cl_id = cl_id;
                break
            else
                disp(['Load: No data for Cluster ' num2str(cl_id)])
            end
        
        end
        if isempty(hnd.BSCData), error('no BSC data to load'), end
        
        [iso_st,dt] = caa_read_interval;
        if isempty(iso_st)
            hnd.tint = [hnd.BSCData(1,1) hnd.BSCData(1,1)];
        else
            hnd.tint = iso2epoch(iso_st) + [0 dt];
        end
        hnd.ts_marker.t = hnd.tint(1);
        
        % Menu
        hnd.menu_sc = uimenu(h0,'Label','&sc');
        hnd.menu_c1 = uimenu(hnd.menu_sc,'Label','&1',...
            'Callback','c_bsc_gui(''select_c1'')',...
            'Accelerator','1');
        hnd.menu_c2 = uimenu(hnd.menu_sc,'Label','&2',...
            'Callback','c_bsc_gui(''select_c2'')',...
            'Accelerator','2');
        hnd.menu_c3 = uimenu(hnd.menu_sc,'Label','&3',...
            'Callback','c_bsc_gui(''select_c3'')',...
            'Accelerator','3');
        hnd.menu_c4 = uimenu(hnd.menu_sc,'Label','&4',...
            'Callback','c_bsc_gui(''select_c4'')',...
            'Accelerator','4');
        c_eval('set(hnd.menu_c?,''Enable'',''off'')',hnd.cl_id)
        
        hnd.menu_b_sc = uimenu(h0,'Label','&B-SC');
        hnd.menu_get_data = uimenu(hnd.menu_b_sc,'Label','&Get data',...
            'Callback','c_bsc_gui(''get_data'')',...
            'Accelerator','g');
        hnd.menu_get_data = uimenu(hnd.menu_b_sc,'Label','&Compare to FGM',...
            'Callback','c_bsc_gui(''compare_fgm'')',...
            'Accelerator','f');
        hnd.menu_save_data = uimenu(hnd.menu_b_sc,'Label','&Save to disk',...
            'Callback','c_bsc_gui(''save_data'')',...
            'Accelerator','d',...
            'Enable','off');
        
        % Create Data Axes
        hnd.Xaxes = irf_subplot(3,1,-1);
        hnd.Yaxes = irf_subplot(3,1,-2);
        hnd.Zaxes = irf_subplot(3,1,-3);
        
        guidata(h0,hnd);
        
        c_bsc_gui('replot_all')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% replot_all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'replot_all'
        % Replot all data
        hnd = guidata(h0);
        h = [hnd.Xaxes hnd.Yaxes hnd.Zaxes];
        
        leg='xyz';
        for comp=1:3
            plot(h(comp),hnd.BSCData(:,1),hnd.BSCData(:,comp+1));
            if ~isempty(hnd.BSCDataAppend)
                hold(h(comp),'on')
                plot(h(comp),...
                    hnd.BSCDataAppend(:,1),hnd.BSCDataAppend(:,comp+1),...
                    'Color',[0 .5 0]);
                hold(h(comp),'off')
            end
            ylabel(h(comp),['B_' leg(comp) ' [nT]'])
        end
        
        % Time span
        irf_zoom(hnd.tint,'x',h);
        
        update_title(hnd)
        
        hnd.ts_marker = replot_t_marker(hnd,hnd.ts_marker);
        
        set(hnd.Xaxes,'Tag','Xaxes',...
            'ButtonDownFcn','c_bsc_gui(''click_Xaxes'')');
        set(hnd.Yaxes,'Tag','Yaxes',...
            'ButtonDownFcn','c_bsc_gui(''click_Yaxes'')');
        set(hnd.Zaxes,'Tag','Zaxes',...
            'ButtonDownFcn','c_bsc_gui(''click_Zaxes'')');
        
        guidata(h0,hnd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% click_axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'click_axes'
        hnd = guidata(h0);
        
        t = get(eval(['hnd.' curr_ax 'axes']),'CurrentPoint');
        t = t(1);
        
        hnd.ts_marker.t = t;
        hnd.ts_marker = replot_t_marker(hnd,hnd.ts_marker);
        
        update_title(hnd)
        
        guidata(h0,hnd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% update_sc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
    case 'update_sc'
        hnd = guidata(h0);
        
        [ok, data] = c_load('wBSC?',curr_sc);
        if ok && ~isempty(data)
            hnd.BSCData = data;
            hnd.ts_marker.t = data(1,1);
            hnd.BSCDataAppend = [];
            hnd.diB = [];
            hnd.diBSC = [];
            hnd.pha = [];
            c_eval('set(hnd.menu_c?,''Enable'',''on'')',hnd.cl_id)
            hnd.cl_id = curr_sc;
            c_eval('set(hnd.menu_c?,''Enable'',''off'')',hnd.cl_id)
            set(hnd.menu_save_data,'Enable','off')
            
            guidata(h0,hnd);
            c_bsc_gui('replot_all')
        else
            disp(['Load: No data for Cluster ' num2str(curr_sc)])
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
    case 'get_data'
        hnd = guidata(h0);
        
        DT_OFF = 120;
        
        data = getData(...
            ClusterDB(c_ctl(0,'isdat_db'), c_ctl(0,'data_path'), '.'), ...
            hnd.ts_marker.t-DT_OFF,...
            hnd.tint(2) - hnd.ts_marker.t + 2*DT_OFF,...
            hnd.cl_id, 'bsc','nosave');
       
        if ~isempty(data)
            hnd.BSCDataAppend = irf_tlim(data{2},hnd.ts_marker.t,hnd.tint(2));
            set(hnd.menu_save_data,'Enable','on')
            
            guidata(h0,hnd);
            c_bsc_gui('replot_all')
        else
            disp(['Load: No data for Cluster ' num2str(curr_sc) ' '...
                epoch2iso(hnd.ts_marker.t-DT_OFF,1) ' -- '...
                epoch2iso(hnd.tint(2)+DT_OFF,1)])
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'save_data'
        hnd = guidata(h0);
        
        if hnd.BSCData(1,1) < hnd.BSCDataAppend(1,1)
            hnd.BSCData = irf_tlim(hnd.BSCData,...
                hnd.BSCData(1,1),hnd.BSCDataAppend(1,1));
            hnd.BSCData = [hnd.BSCData; hnd.BSCDataAppend];
        else
            hnd.BSCData = hnd.BSCDataAppend;
        end
        hnd.BSCDataAppend = [];
        hnd.diBSC =[];
        
        set(hnd.menu_save_data,'Enable','off')
        
        c_eval('wBSC?=hnd.BSCData; save mBSCR.mat wBSC? -append',hnd.cl_id)
        getData(ClusterProc,hnd.cl_id,'dibsc')
        
        guidata(h0,hnd);
        c_bsc_gui('replot_all')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compare_fgm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'compare_fgm'
        hnd = guidata(h0);
        
        if isempty(hnd.pha)
            [ok,hnd.pha, msg] = c_load('Atwo?',hnd.cl_id);
            if ~ok || isempty(hnd.pha)
                irf_log('load',msg)
                return
            end
        end
        
        if isempty(hnd.diBSC)
            aa = c_phase(hnd.BSCData(:,1),hnd.pha);
            diBSC = c_efw_despin(hnd.BSCData,aa);
            % DS-> DSI
            diBSC(:,3)=-diBSC(:,3);
            diBSC(:,4)=-diBSC(:,4);
            hnd.diBSC = diBSC;
            clear diBSC aa
        end
        
        if ~isempty(hnd.BSCDataAppend)
            aa = c_phase(hnd.BSCDataAppend(:,1),hnd.pha);
            diBSCAppend = c_efw_despin(hnd.BSCDataAppend,aa);
            % DS-> DSI
            diBSCAppend(:,3)=-diBSCAppend(:,3);
            diBSCAppend(:,4)=-diBSCAppend(:,4);    
            clear aa
        else
            diBSCAppend = [];
        end
        
        if isempty(hnd.diB)
            [ok, hnd.diB, msg] = c_load('diB?',hnd.cl_id);
            if ~ok || isempty(hnd.diB)
                irf_log('load',msg)
                hnd.diB = [];
            end
        end
        
        figure(main_fig_id+1), clf
        h = irf_plot({hnd.diBSC,diBSCAppend,hnd.diB},'comp');
        irf_zoom(hnd.tint,'x',h);
        
        leg='xyz';
        for comp = 1:3
            ylabel(h(comp),['B_' leg(comp) ' [nT]'])
        end
        title(h(1), ['Cluster ' num2str(hnd.cl_id) ' DSI'])
        if isempty(hnd.BSCDataAppend), legend(h(3),{'orig','fgm'})
        else legend(h(3),{'orig','new','fgm'})
        end
        
        guidata(h0,hnd);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function hide_t_marker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newmarker = hide_t_marker(hnd,marker) %#ok<INUSL>
newmarker.t = [];
if ~isempty(marker)
	newmarker.t = marker.t;
	% Hide the marker if marker.h exists
	if isfield(marker,'h')
		lasterr('')
		try
			for j=3:-1:1, delete(marker.h(j)),end
		catch
			%disp('missed marker')
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function replot_t_marker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newmarker = replot_t_marker(hnd,marker)
h = [hnd.Xaxes hnd.Yaxes hnd.Zaxes];

% Try to hide the marker
newmarker = hide_t_marker(hnd,marker);

for j=1:length(h)
    yy = get(h(j),'YLim');
    hold(h(j),'on')
    newmarker.h(j) = plot(h(j),[newmarker.t newmarker.t],yy,...
        'LineWidth',1,'Color','red');
    hold(h(j),'off')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function update_title
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_title(hnd)
title(hnd.Xaxes, ['Cluster ' num2str(hnd.cl_id) ...
            ' Start: ' epoch2iso(hnd.ts_marker.t,1)])
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function load_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function res = load_data(h0,cl_id)
hnd = guidata(h0);

[ok, data] = c_load('wBSC?',cl_id);
if ok && ~isempty(data)
    res = 1;
    hnd.BSCData = data;
    hnd.cl_id = cl_id;
    guidata(h0,hnd);
else
    res = 0;
    disp(['Load: No data for Cluster ' num2str(cl_id)])
end
  