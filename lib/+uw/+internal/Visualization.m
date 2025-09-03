classdef Visualization
    % VISUALIZATION  Internal helper functions for plotting environment and TL.

    methods (Static)
        function fig = plotTLSlice(sim, bearing_idx, varargin)
            % plotTLSlice  Plot TL slice for a given bearing index.
            %   FIG = plotTLSlice(SIM, BEARING_IDX, 'ComputeBellhop', TF)
            %   When ComputeBellhop is true, recomputes the .shd before plotting.
          
            p = inputParser;
            addParameter(p, 'ComputeBellhop', true, @islogical);
            parse(p, varargin{:});
            computeBellhop = p.Results.ComputeBellhop;

            if ~isfile(sim.settings.filename + ".shd") || computeBellhop
                bellhop3d(sim.settings.filename);
            end

            fig = figure; title('Transmission loss','FontSize',10);
            %plotshd(sim.settings.filename + ".shd");
            plotshd_custom("Filename", char(sim.settings.filename + ".shd"), "BearingIdx", bearing_idx);
        end

        function plotSSP(sim)
            % plotSSP  Plot 3-D sound-speed profile using Bellhop tools.
            %   plotSSP(SIM) uses plotssp3d when an .ssp exists,
            %   otherwise plotssp on .env.
            figure; title('SSP Plot','FontSize',10);

            if isfile(sim.settings.filename + ".ssp")
                plotssp3d(sim.settings.filename + ".ssp");
            else
                plotssp(sim.settings.filename + ".env");
            end
        end

        function plotTLPolar(sim, varargin)
            % plotTLPolar  Polar TL plot around the source.
            %   plotTLPolar(SIM, 'ComputeBellhop', TF)
            p = inputParser;
            addParameter(p, 'ComputeBellhop', true, @islogical);
            parse(p, varargin{:});
            computeBellhop = p.Results.ComputeBellhop;

            % Check if .shd file exists
            if not(isfile(sim.settings.filename + ".shd")) || computeBellhop
                bellhop3d(sim.settings.filename)
            end

            figure; title('Transmission loss','FontSize',10);

            % Have to modify it to chose source depth
            plotshdpol_custom(char(sim.settings.filename + ".shd") , sim.settings.sim_source_x, sim.settings.sim_source_y, sim.settings.sim_source_depth );
           

        end

        function printBTY(sim)
            % printBTY  Plot bathymetry (.bty) if in use.
            if sim.settings.sim_use_bty_file
                figure; title('Bathymetry (BTY)'); plotbdry3d(sim.settings.filename + ".bty");
            else
                fprintf("Bathymetry file not in use, no plot available. \n");
            end
        end
    end
end

% --------- Ausiliary functions ---------

function varargout = plotshd_custom( varargin )

% plot a single TL surface in dB
% usage:
% plotshd( filename, m, n, p, bearing_idx, source_idx )
% (bearing_idx, source_idx) optional spec
% (m, n, p) optional subplot spec
% '.shd' is the default file extension if not specified in the filename
%
% plotshd( filename, freq )          to plot field for a specified frequency
% plotshd( filename, freq, m, n, p ) to plot field for a specified frequency and subplot

global units jkpsflag

% --- Modern Input Parsing ---
p = inputParser;
addParameter(p, 'Filename', '');
addParameter(p, 'BearingIdx', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'SourceIdx', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'freq', []);
addParameter(p, 'm', []);
addParameter(p, 'n', []);
addParameter(p, 'p', []);
parse(p, varargin{:});

% These variables are needed by the legacy code's 'squeeze' command
itheta = p.Results.BearingIdx;
isz    = p.Results.SourceIdx;

% --- Create a legacy-style cell array from the parsed inputs ---
legacy_args = {p.Results.Filename};
if ~isempty(p.Results.m) % Subplot call
    if ~isempty(p.Results.freq) % Freq and subplots
        legacy_args = [legacy_args, p.Results.freq, p.Results.m, p.Results.n, p.Results.p];
    else % Just subplots
        legacy_args = [legacy_args, p.Results.m, p.Results.n, p.Results.p];
    end
elseif ~isempty(p.Results.freq) % Just freq
    legacy_args = [legacy_args, p.Results.freq];
end

% The following code is the original block, with 'varargin' and 'nargin'
% replaced by 'legacy_args' and 'numel(legacy_args)' respectively.

% START of the standard plotshd function 
filename = legacy_args{ 1 };
switch numel(legacy_args)
   case 1   % straight call
      [ PlotTitle, ~, freqVec, ~, ~, Pos, pressure ] = read_shd( filename );
      freq = freqVec( 1 );
   case 2   % a frequency has been selected
      freq = legacy_args{ 2 };
      [ PlotTitle, ~, freqVec, ~, ~, Pos, pressure ] = read_shd( filename, freq );
   case 4   % a subplot m n p has been selected
      m = legacy_args{ 2 };
      n = legacy_args{ 3 };
      p = legacy_args{ 4 };      
      [ PlotTitle, ~, freqVec, ~, ~, Pos, pressure ] = read_shd( filename );
      freq = freqVec( 1 );
   case 5   % a frequency and a subplot m n p has been selected
      freq = legacy_args{ 2 };
      m    = legacy_args{ 3 };
      n    = legacy_args{ 4 };
      p    = legacy_args{ 5 };      
      [ PlotTitle, ~, freqVec, ~, ~, Pos, pressure ] = read_shd( filename, freq );
end
PlotTitle = replace( PlotTitle, '_', ' ' );
pressure = squeeze( pressure( itheta, isz, :, : ) );
zt       = Pos.r.z;
rt       = Pos.r.r;
xlab     = 'Range (m)';
if ( strcmp( units, 'km' ) )
   rt    = rt / 1000.0;
   xlab  = 'Range (km)';
end
if ( numel(legacy_args) == 1 || numel(legacy_args) == 2 )
   %figure
else
   if ( p == 1 )
      figure
   else
      hold on
   end
   subplot( m, n, p )
end
%%
% calculate caxis limits
if ( length( PlotTitle ) >= 5 && strcmp( PlotTitle( 1 : 5 ), 'SPARC' ) )
   tlt = real( pressure );
   tlt = 1e6 * tlt;
   tlmax = max( max( abs( tlt ) ) );
   tlmax = 0.4 * max( tlmax, 0.000001 );
   tlmin = -tlmax;
else
   tlt = double( abs( pressure ) );
   tlt( isnan( tlt ) ) = 1e-6;
   tlt( isinf( tlt ) ) = 1e-6;
   icount = find( tlt > 1e-37 );
   tlt( tlt < 1e-37 ) = 1e-37;
   tlt = -20.0 * log10( tlt );
   tlmed = median( tlt( icount ) );
   tlstd = std( tlt( icount ) );
   tlmax = tlmed + 0.75 * tlstd;
   tlmax = 10 * round( tlmax / 10 );
   tlmin = tlmax - 50;
end
%%
% plot
tej = flipud( jet( 256 ) );
if ( size( tlt, 1 ) > 1 && size( tlt, 2 ) > 1 )
   h = pcolor( rt, zt, tlt );
   shading flat
   colormap( tej )
   caxis( [ tlmin, tlmax ] )
   set( gca, 'YDir', 'Reverse' )
   set( gca, 'TickDir', 'out' )
   set( findall( gcf, 'type', 'ColorBar' ), 'TickDir', 'out' )
   xlabel( xlab )
   ylabel( 'Depth (m)' );
   title( { deblank( PlotTitle ); [ 'Freq = ' num2str( freq ) ' Hz    z_{src} = ' num2str( Pos.s.z( isz ) ) ' m' ] } )
else
   if ( size( Pos.r.r, 1 ) > 1 )
      h = plot( rt, tlt );
      xlabel( xlab );
      ylabel( 'TL (dB)' )
      set( h, 'LineWidth', 2 )
      set( gca, 'YDir', 'Reverse' )
      title( { deblank( PlotTitle ); [ 'Freq = ' num2str( freq ) ' Hz    z_{src} = ' num2str( Pos.s.z( isz ) ) ' m' ] } )
   else
      h = plot( tlt', zt );
      set( gca, 'YDir', 'Reverse' )
      set( gca, 'XDir', 'Reverse' )
      set( h, 'LineWidth', 2 )
      xlabel( 'TL (dB)' )
      ylabel( 'Depth (m)' );
      title( { deblank( PlotTitle ); [ 'Freq = ' num2str( freq ) ' Hz    z_{src} = ' num2str( Pos.s.z( isz ) ) ' m' ] } )
   end
end
drawnow
if ( nargout == 1 )
   varargout( 1 ) = { h };
end
%%
% fixed size for publications
if ~exist('jkpsflag', 'var'), jkpsflag = 0; end
if ( jkpsflag )
   set( gca, 'ActivePositionProperty', 'Position', 'Units', 'centimeters' )
   set( gcf, 'Units', 'centimeters' )
   set( gcf, 'PaperPositionMode', 'auto');
   if ( exist( 'm', 'var' ) )
      set( gca, 'Position', [ 2    2 + ( m - p ) * 9.0     14.0       7.0 ] )
      set( gcf, 'Position', [ 3                   15.0     19.0  m * 10.0 ] )
   else
      set( gca, 'Position', [ 2    2                       14.0       7.0 ] )
      set( gcf, 'Units', 'centimeters' )
      set( gcf, 'Position', [ 3 15 19.0 11.0 ] )
   end
end
end

function plotshdpol_custom( varargin )

% plot a TL surface in dB (polar coordinates)
% usage:
% plotshdpol( filename )
%    or
% plotshdpol( filename, xs, ys, rd )
% where
%   xs, ys is the source coordinate in km
%   rd is the receiver depth in m

global units

filename = varargin{1};

if ( nargin == 2  || nargin == 3 )
   % Generate a warning.
   Message = 'Call plotshdpol with 1 or 4 inputs.';
   warning( Message );
end

if nargin > 1
   xsvec = varargin{ 2 };
   ysvec = varargin{ 3 };
   rd    = varargin{ 4 };
else
   xsvec = NaN;
   ysvec = NaN;
   rd    = 0.0;
end

% open the file and read data

isz = 1;   % select a source depth

for xs =  xsvec
   for ys = ysvec
      [ PlotTitle, ~, freqVec, ~, ~, Pos, pressure ] = read_shd( filename, xs, ys );
      PlotTitle = replace( PlotTitle, '_', ' ' );  % Get rid of underlines (for Laurel who uses them in titles)

      % get nrz so that tlt doesn't loose the singleton dimension when nrz = 1
      nrz = length( Pos.r.z );
      clear tlt
      tlt( :, 1 : nrz, : ) = abs( pressure( :, isz, :, : ) );   % taken chosen source depth
      %tlt( :, 1 : nrd, : ) = abs( pressure( 1, 1, :, isz, :, : ) );   % take chosen source depth
      
      tlt = permute( tlt, [ 2 1 3 ] );   % order so that TL( rd, x, y )
      
      % interpolate the TL field at the receiver depth
      % note: interp1 won't interpolate a vector with only 1 element
      
      if ( length( Pos.r.z ) == 1 )
         tl = squeeze( tlt( 1, :, : ) );
      else
         tl = squeeze( interp1( Pos.r.z, tlt, rd ) );
      end
      
      tl( isnan( tl ) ) = 1e-6;   % remove NaNs
      tl( isinf( tl ) ) = 1e-6;   % remove infinities
      tl( tl < 1e-37  ) = 1e-37;  % remove zeros
      
      tl = -20.0 * log10( tl );
      
      % if full circle, duplicate the first bearing
      
      ntheta = length( Pos.theta );
      d_theta = ( Pos.theta( end ) - Pos.theta( 1 ) ) / ( ntheta - 1 );
      
      if ( mod( Pos.theta( end ) + d_theta - Pos.theta( 1 ) + .001, 360.0 ) < .002 )
         Pos.theta( end + 1 ) = Pos.theta( end ) + d_theta;
         tl( end + 1, : ) = tl( 1, : );
      end
      tl = tl';
      
      % make plot polar
      
      [ th, r ] = meshgrid( Pos.theta, Pos.r.r );
      
      th        = ( 2 * pi / 360. ) * th;   % convert to radians
      [ x, y ]  = pol2cart( th, r );
      
      % offset grid by the source coordinate
      if ( isnan( xs ) && isnan( ys ) )
         xst = Pos.s.x / 1000;
         yst = Pos.s.y / 1000;
      else
         xst = xs;
         yst = ys;
      end
      
      xt = x + 1000. * xst * ones( size( x ) );
      yt = y + 1000. * yst * ones( size( x ) );
         
      if ( strcmp( units, 'km' ) )
         xt = xt / 1000;   % convert to km
         yt = yt / 1000;
      end

      % *** plot ***
      
      tej = flipud( jet( 256 ) );  % 'jet' colormap reversed
      %tej = flipud( parula( 256 ) );  % 'parula' colormap reversed
      
      surf( xt, yt, tl ); shading interp
      % surfc( x, y, tl ); shading interp
      % pcolor( x, y, tl ); shading flat
      
      colormap( tej );
      colorbar

      tl_min = prctile(tl(:), 1);   % 1st percentile
      tl_max = prctile(tl(:), 95);  % 95th percentile (ignore top 5%)
      caxis([tl_min tl_max])

      view( 2 )
      xlabel( 'Range, x (m)' )
      ylabel( 'Range, y (m)' )
      if ( strcmp( units, 'km' ) )
         xlabel( 'Range, x (km)' )
         ylabel( 'Range, y (km)' )
      end
      
      zlabel( 'Depth (m)' )

      title( { deblank( PlotTitle ); [ ...
         'Freq = '     num2str( freqVec( 1 )   ) ' Hz   ' ...
         'x_{src} = '  num2str( xst            ) ' km   ' ...
         'y_{src} = '  num2str( yst            ) ' km   ' ...
         'z_{src} = '  num2str( Pos.s.z( isz ) ) ' m     ' ...
         'z_{rcvr} = ' num2str( rd             ) ' m' ] } )
       
% axis( 'image' )
      drawnow
      hold on
   end
end

%

% fixed size for publications
% set( gca, 'ActivePositionProperty', 'Position', 'Units', 'centimeters' )
% set( gcf, 'Units', 'centimeters' )
% set( gcf, 'PaperPositionMode', 'auto');   % this is important; default is 6x8 inch page
% set( gca, 'Position', [ 1    0                       14.0       7.0 ] )
% set( gcf, 'Units', 'centimeters' )
% set( gcf, 'Position', [ 1 15 17.0 7.5 ] )

%     set( gcf, 'Units', 'centimeters' )
%     set( gcf, 'PaperPositionMode', 'manual' );
%     set( gcf, 'PaperPosition', [ 3 3 15.0 10.0 ] )

end