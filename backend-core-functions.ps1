function Create-Common-Files{
@"
using Serilog;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using $($SolutionName).Application.Interfaces;

namespace $($SolutionName).Application.Common.Behaviors
{
    public class LoggingBehavior<TRequest, TResponse>
        : IPipelineBehavior<TRequest, TResponse> where TRequest
        : IRequest<TResponse>
    {
        ICurrentUserService _currentUserService;

        public LoggingBehavior(ICurrentUserService currentUserService) =>
            _currentUserService = currentUserService;

        public async Task<TResponse> Handle(TRequest request
		,RequestHandlerDelegate<TResponse> next
            ,CancellationToken cancellationToken
            )
        {
            var requestName = typeof(TRequest).Name;
            var userId = _currentUserService.UserId;

            Log.Information("$($SolutionName) Request: {Name} {@UserId} {@Request}",
                requestName, userId, request);

            var response = await next();

            return response;
        }
		

    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\Common\Behaviors\LoggingBehavior.cs"



@" 
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using FluentValidation;

namespace $($SolutionName).Application.Common.Behaviors
{
    public class ValidationBehavior<TRequest, TResponse>
        : IPipelineBehavior<TRequest, TResponse> where TRequest : IRequest<TResponse>
    {
        private readonly IEnumerable<IValidator<TRequest>> _validators;

        public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators) =>
            _validators = validators;

        public Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next,
            CancellationToken cancellationToken)
        {
            var context = new ValidationContext<TRequest>(request);
            var failures = _validators
                .Select(v => v.Validate(context))
                .SelectMany(result => result.Errors)
                .Where(failure => failure != null)
                .ToList();
            if (failures.Count != 0)
            {
                throw new ValidationException(failures);
            }
            return next();
        }
    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\Common\Behaviors\ValidationBehavior.cs"

@"
using System;

namespace $($SolutionName).Application.Common.Exceptions
{
    public class NotFoundException : Exception
    {
        public NotFoundException(string name, object key)
            : base($"Entity \"{name}\" ({key}) not found.") { }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\Common\Exceptions\NotFoundException.cs"

@" 
using System;
using System.Linq;
using System.Reflection;
using AutoMapper;

namespace $($SolutionName).Application.Common.Mappings
{
    public class AssemblyMappingProfile : Profile
    {
        public AssemblyMappingProfile(Assembly assembly) =>
            ApplyMappingsFromAssembly(assembly);

        private void ApplyMappingsFromAssembly(Assembly assembly)
        {
            var types = assembly.GetExportedTypes()
                .Where(type => type.GetInterfaces()
                    .Any(i => i.IsGenericType &&
                    i.GetGenericTypeDefinition() == typeof(IMapWith<>)))
                .ToList();

            foreach (var type in types)
            {
                var instance = Activator.CreateInstance(type);
                var methodInfo = type.GetMethod("Mapping");
                methodInfo?.Invoke(instance, new object[] { this });
            }
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\Common\Mappings\AssemblyMappingProfile.cs"

@"
using AutoMapper;

namespace $($SolutionName).Application.Common.Mappings
{
    public interface IMapWith<T>
    {
        void Mapping(Profile profile) =>
            profile.CreateMap(typeof(T), GetType());
    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\Common\Mappings\IMapWith.cs"

@" 
using System.Reflection;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using $($SolutionName).Application.Common.Behaviors;

namespace $($SolutionName).Application
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddApplication(
            this IServiceCollection services)
        {
            services.AddMediatR(Assembly.GetExecutingAssembly());
            services
                .AddValidatorsFromAssemblies(new[] { Assembly.GetExecutingAssembly() });
            services.AddTransient(typeof(IPipelineBehavior<,>),
                typeof(ValidationBehavior<,>));
            services.AddTransient(typeof(IPipelineBehavior<,>),
                typeof(LoggingBehavior<,>));
            return services;
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\DependencyInjection.cs"

@" 
using System;

namespace $($SolutionName).Application.Interfaces
{
    public interface ICurrentUserService
    {
        Guid UserId { get; }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\Interfaces\ICurrentUserService.cs"


	
	
}

function Create-Model-Files   {
	param(
            [Parameter(Mandatory=$true)]
            [PSCustomObject[]]$models
        )
		
		$dbsetStr=""
		
	foreach ($model in $models) {

	$dbsetStr=$dbsetStr+"`r`n"+"DbSet<$($model.ModelName)> $($model.ModelName)s { get; set; }"
	$fieldsStr=""
	foreach ($field in $model.Fields) {
      $fieldsStr=$fieldsStr+"`r`n"+"public $($field.FieldType) $($field.FieldName) { get; set; }"
	}

	@"
namespace $($SolutionName).Domain
{
public class $($model.ModelName)
{
	public Guid UserId { get; set; }
    $($fieldsStr)
}
}
"@ | Set-Content -Path "Core\$($SolutionName).Domain\$($model.ModelName).cs"
	
Create-Command-Files -model $model
Create-Update-Files -model $model
Create-Delete-Files -model $model
Create-Queries-Files -model $model
		}
		
		@" 
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.Interfaces
{
    public interface I$($SolutionName)DbContext
    {
        $($dbsetStr)
        Task<int> SaveChangesAsync(CancellationToken cancellationToken);
    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\Interfaces\I$($SolutionName)DbContext.cs"	
		
}

function Get-Field-Rule {
 
        param(
            [Parameter(Mandatory=$true)]
            [string]$ftype
)

$rule =""

 if ($ftype -eq " Guid"){
	 $rule="NotEqual($($ftype).Empty)"
	  }else{
		  $rule = "NotEmpty()"
		  
	  }
	  
	  
	  
return $rule
}

function Create-Command-Files {
 
        param(
            [Parameter(Mandatory=$true)]
            [PSCustomObject]$model
        )
    
	$fieldsStr=""
	$handleStr=""
	 $fieldsCommandValidatorStr=""
	$rule="" 
	foreach ($field in $model.Fields) {
      $fieldsStr=$fieldsStr+"`r`n"+"public $($field.FieldType) $($field.FieldName) { get; set; }"
	  
	  $handleStr=$handleStr+"`r`n"+"$($field.FieldName) = request.$($field.FieldName),"
	  
	  
	 
	 $rule = Get-Field-Rule -ftype $field.FieldType
	  
	  
	   $fieldsCommandValidatorStr=$fieldsCommandValidatorStr+"`r`n"+"RuleFor(update$($model.ModelName)Command => update$($model.ModelName)Command.$($field.FieldName)).$($rule);"
	   
	   
	}
	
	New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\CreateCommand" -Force	
@" 
using System;
using MediatR;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.Create$($model.ModelName)
{
    public class Create$($model.ModelName)Command : IRequest<Guid>
    {
	   public Guid UserId { get; set; }
       $($fieldsStr)
    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\CreateCommand\Create$($model.ModelName)Command.cs"   



@" 
using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using $($SolutionName).Application.Interfaces;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.Create$($model.ModelName)
{
    public class Create$($model.ModelName)CommandHandler
        :IRequestHandler<Create$($model.ModelName)Command, Guid>
    {
        private readonly I$($SolutionName)DbContext _dbContext;

        public Create$($model.ModelName)CommandHandler(I$($SolutionName)DbContext dbContext) =>
            _dbContext = dbContext;

        public async Task<Guid> Handle(Create$($model.ModelName)Command request,
            CancellationToken cancellationToken)
        {
            var obj = new $($model.ModelName)
            {
				$handleStr
                
            };

            await _dbContext.$($model.ModelName)s.AddAsync(obj, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return obj.Id;
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\CreateCommand\Create$($model.ModelName)CommandHandler.cs"

@" 
using System;
using FluentValidation;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.Create$($model.ModelName)
{
    public class Create$($model.ModelName)CommandValidator : AbstractValidator<Create$($model.ModelName)Command>
    {
        public Create$($model.ModelName)CommandValidator()
        {
            $($fieldsCommandValidatorStr)
        }
    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\CreateCommand\Create$($model.ModelName)CommandValidator.cs"
}

function Create-Update-Files {
    param(
            [Parameter(Mandatory=$true)]
            [PSCustomObject]$model
        )
    
	$fieldsStr = ""
	$fieldsUpdateValidatorStr = ""
	$updateCommandHandlerStr = ""
	 
	foreach ($field in $model.Fields) {
		
      $fieldsStr = $fieldsStr+"`r`n"+"public $($field.FieldType) $($field.FieldName) { get; set; }"	  
	   
	  $rule = Get-Field-Rule -ftype $field.FieldType
	   
	  $fieldsUpdateValidatorStr = $fieldsUpdateValidatorStr+"`r`n"+"RuleFor(update$($model.ModelName)Command => update$($model.ModelName)Command.$($field.FieldName)).$($rule);"
	  
	  $updateCommandHandlerStr = $updateCommandHandlerStr+"`r`n"+"entity.$($field.FieldName) = request.$($field.FieldName);"
	  
	}
	
	
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\UpdateCommand" -Force	
	
@" 
using System;
using MediatR;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.Update$($model.ModelName)
{
    public class Update$($model.ModelName)Command : IRequest
    {
		public Guid UserId { get; set; }
        $($fieldsStr)
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\UpdateCommand\Update$($model.ModelName)Command.cs"
@" 
using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Application.Interfaces;
using $($SolutionName).Application.Common.Exceptions;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.Update$($model.ModelName)
{
    public class Update$($model.ModelName)CommandHandler
        : IRequestHandler<Update$($model.ModelName)Command>
    {
        private readonly I$($SolutionName)DbContext _dbContext;

        public Update$($model.ModelName)CommandHandler(I$($SolutionName)DbContext dbContext) =>
            _dbContext = dbContext;

        public async Task<Unit> Handle(Update$($model.ModelName)Command request,
            CancellationToken cancellationToken)
        {
            var entity =
                await _dbContext.$($model.ModelName)s.FirstOrDefaultAsync(model =>
                    model.Id == request.Id, cancellationToken);

            if (entity == null || entity.UserId != request.UserId)
            {
                throw new NotFoundException(nameof($($model.ModelName)), request.Id);
            }

             $($updateCommandHandlerStr)

            await _dbContext.SaveChangesAsync(cancellationToken);

            return Unit.Value;
        }
    }
}


"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\UpdateCommand\Update$($model.ModelName)CommandHandler.cs"
@" 
using System;
using FluentValidation;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.Update$($model.ModelName)
{
    public class Update$($model.ModelName)CommandValidator : AbstractValidator<Update$($model.ModelName)Command>
    {
        public Update$($model.ModelName)CommandValidator()
        {
           $($fieldsUpdateValidatorStr)
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\UpdateCommand\Update$($model.ModelName)CommandValidator.cs"
}

function Create-Delete-Files {    
        param(
            [Parameter(Mandatory=$true)]
            [PSCustomObject]$model
        )
    
	$fieldsStr=""
	$fieldsDeleteValidatorStr=""	
	 
	foreach ($field in $model.Fields) {
		if ($field.KeyField -eq 1)
		{
      $fieldsStr=$fieldsStr+"`r`n"+"public $($field.FieldType) $($field.FieldName) { get; set; }"	 
	  $rule = Get-Field-Rule -ftype $field.FieldType
	  $fieldsDeleteValidatorStr = $fieldsDeleteValidatorStr+"`r`n"+"RuleFor(delete$($model.ModelName)Command => delete$($model.ModelName)Command.$($field.FieldName)).$($rule);"				
			
		}

	  
	  
	}

	
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\DeleteCommand" -Force
@" 
using System;
using MediatR;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.DeleteCommand
{
    public class Delete$($model.ModelName)Command : IRequest
    {
        public Guid UserId { get; set; }
        public Guid Id { get; set; }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\DeleteCommand\Delete$($model.ModelName)Command.cs"
@" 
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using $($SolutionName).Application.Interfaces;
using $($SolutionName).Application.Common.Exceptions;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.DeleteCommand
{
    public class Delete$($model.ModelName)CommandHandler
        : IRequestHandler<Delete$($model.ModelName)Command>
    {
        private readonly I$($SolutionName)DbContext _dbContext;

        public Delete$($model.ModelName)CommandHandler(I$($SolutionName)DbContext dbContext) =>
            _dbContext = dbContext;

        public async Task<Unit> Handle(Delete$($model.ModelName)Command request,
            CancellationToken cancellationToken)
        {
            var entity = await _dbContext.$($model.ModelName)s
                .FindAsync(new object[] { request.Id }, cancellationToken);

            if (entity == null || entity.UserId != request.UserId)
            {
                throw new NotFoundException(nameof($($model.ModelName)), request.Id);
            }

            _dbContext.$($model.ModelName)s.Remove(entity);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return Unit.Value;
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\DeleteCommand\Delete$($model.ModelName)CommandHandler.cs"
@" 
using System;
using FluentValidation;

namespace $($SolutionName).Application.$($model.ModelName)s.Commands.DeleteCommand
{
    public class Delete$($model.ModelName)CommandValidator : AbstractValidator<Delete$($model.ModelName)Command>
    {
        public Delete$($model.ModelName)CommandValidator()
        {
            $($fieldsDeleteValidatorStr)
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Commands\DeleteCommand\Delete$($model.ModelName)CommandValidator.cs"
}

function Create-Queries-Files {
   param(
            [Parameter(Mandatory=$true)]
            [PSCustomObject]$model
        )
    
	$fieldsStr=""
	$mapStr = ""
	 
	foreach ($field in $model.Fields) {
      $fieldsStr=$fieldsStr+"`r`n"+"public $($field.FieldType) $($field.FieldName) { get; set; }"	  
	$mapStr = $mapStr+"`r`n"+".ForMember(modelVm => modelVm.$($field.FieldName),
                    opt => opt.MapFrom(model => model.$($field.FieldName)))"
	}
	
	
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetDetails" -Force
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetList" -Force	
	
@" 
using System;
using MediatR;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)Details
{
    public class Get$($model.ModelName)DetailsQuery : IRequest<$($model.ModelName)DetailsVm>
    {
		public Guid UserId { get; set; }
        $($fieldsStr)
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetDetails\Get$($model.ModelName)DetailsQuery.cs"
@" 
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using $($SolutionName).Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Application.Common.Exceptions;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)Details
{
    public class Get$($model.ModelName)DetailsQueryHandler
        : IRequestHandler<Get$($model.ModelName)DetailsQuery, $($model.ModelName)DetailsVm>
    {
        private readonly I$($SolutionName)DbContext _dbContext;
        private readonly IMapper _mapper;

        public Get$($model.ModelName)DetailsQueryHandler(I$($SolutionName)DbContext dbContext,
            IMapper mapper) => (_dbContext, _mapper) = (dbContext, mapper);

        public async Task<$($model.ModelName)DetailsVm> Handle(Get$($model.ModelName)DetailsQuery request,
            CancellationToken cancellationToken)
        {
            var entity = await _dbContext.$($model.ModelName)s
                .FirstOrDefaultAsync(model =>
                model.Id == request.Id, cancellationToken);

            if (entity == null || entity.UserId != request.UserId)
            {
                throw new NotFoundException(nameof($($model.ModelName)), request.Id);
            }

            return _mapper.Map<$($model.ModelName)DetailsVm>(entity);
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetDetails\Get$($model.ModelName)DetailsQueryHandler.cs"
@" 
using System;
using FluentValidation;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)Details
{
    public class Get$($model.ModelName)DetailsQueryValidator : AbstractValidator<Get$($model.ModelName)DetailsQuery>
    {
        public Get$($model.ModelName)DetailsQueryValidator()
        {
            RuleFor(model => model.Id).NotEqual(Guid.Empty);
            RuleFor(model => model.UserId).NotEqual(Guid.Empty);
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetDetails\Get$($model.ModelName)DetailsQueryValidator.cs"
@" 
using System;
using AutoMapper;
using $($SolutionName).Application.Common.Mappings;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)Details
{
    public class $($model.ModelName)DetailsVm : IMapWith<$($model.ModelName)>
    {
        $($fieldsStr)

        public void Mapping(Profile profile)
        {
            profile.CreateMap<$($model.ModelName), $($model.ModelName)DetailsVm>()
				$($mapStr);
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetDetails\$($model.ModelName)DetailsVm.cs"

@" 
using System;
using MediatR;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)List
{
    public class Get$($model.ModelName)ListQuery : IRequest<$($model.ModelName)ListVm>
    {
        public Guid UserId { get; set; }
    }
}
"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetList\Get$($model.ModelName)ListQuery.cs"
@" 
using AutoMapper;
using AutoMapper.QueryableExtensions;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Application.Interfaces;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)List
{
    public class Get$($model.ModelName)ListQueryHandler
        : IRequestHandler<Get$($model.ModelName)ListQuery, $($model.ModelName)ListVm>
    {
        private readonly I$($SolutionName)DbContext _dbContext;
        private readonly IMapper _mapper;

        public Get$($model.ModelName)ListQueryHandler(I$($SolutionName)DbContext dbContext,
            IMapper mapper) =>
            (_dbContext, _mapper) = (dbContext, mapper);

        public async Task<$($model.ModelName)ListVm> Handle(Get$($model.ModelName)ListQuery request,
            CancellationToken cancellationToken)
        {
			
            var modelQuery = await _dbContext.$($model.ModelName)s
                .Where(model => model.UserId == request.UserId)
                .ProjectTo<$($model.ModelName)LookupDto>(_mapper.ConfigurationProvider)
                .ToListAsync(cancellationToken);

            return new $($model.ModelName)ListVm { $($model.ModelName)s = modelQuery };
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetList\Get$($model.ModelName)ListQueryHandler.cs"
@" 
using System;
using FluentValidation;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)List
{
    public class Get$($model.ModelName)ListQueryValidator : AbstractValidator<Get$($model.ModelName)ListQuery>
    {
        public Get$($model.ModelName)ListQueryValidator()
        {
            RuleFor(x => x.UserId).NotEqual(Guid.Empty);
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetList\Get$($model.ModelName)ListQueryValidator.cs"
@" 
using System.Collections.Generic;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)List
{
    public class $($model.ModelName)ListVm
    {
        public IList<$($model.ModelName)LookupDto> $($model.ModelName)s { get; set; }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetList\$($model.ModelName)ListVm.cs"
@" 
using AutoMapper;
using System;
using $($SolutionName).Application.Common.Mappings;
using $($SolutionName).Domain;

namespace $($SolutionName).Application.$($model.ModelName)s.Queries.Get$($model.ModelName)List
{
    public class $($model.ModelName)LookupDto : IMapWith<$($model.ModelName)>
    {
        public Guid Id { get; set; }
        public string Title { get; set; }

        public void Mapping(Profile profile)
        {
            profile.CreateMap<$($model.ModelName), $($model.ModelName)LookupDto>()
                .ForMember(modelDto => modelDto.Id,
                    opt => opt.MapFrom(model => model.Id))
                .ForMember(modelDto => modelDto.Title,
                    opt => opt.MapFrom(model => model.Title));
        }
    }
}

"@ | Set-Content -Path "Core\$($SolutionName).Application\$($model.ModelName)\Queries\GetList\$($model.ModelName)LookupDto.cs"


@"
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using $($SolutionName).Domain;

namespace $($SolutionName).Persistence.EntityTypeConfigurations
{
    public class $($model.ModelName)Configuration : IEntityTypeConfiguration<$($model.ModelName)>
    {
        public void Configure(EntityTypeBuilder<$($model.ModelName)> builder)
        {
            builder.HasKey(model => model.Id);
            builder.HasIndex(model => model.Id).IsUnique();
            builder.Property(model => model.Title).HasMaxLength(250);
        }
    }
}
"@ | Set-Content -Path "Infrastructure\$($SolutionName).Persistence\EntityTypeConfigurations\$($model.ModelName)Configuration.cs"
}

function Create-Persistence-Files{
     param(
        [System.Collections.Generic.List[string]]$ModelList
    )
	$dbsetLine=""
	$configLine=""
	foreach ($model in $ModelList) {
	$dbsetLine=$dbsetLine+"`r`n"+"public DbSet<$($model)> $($model)s { get; set; }"
	$configLine=$configLine+"`r`n"+"builder.ApplyConfiguration(new $($model)Configuration());"
	}
	
@" 
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Application.Interfaces;
using $($SolutionName).Domain;
using $($SolutionName).Persistence.EntityTypeConfigurations;

namespace $($SolutionName).Persistence
{
    public class $($SolutionName)DbContext : DbContext, I$($SolutionName)DbContext
    {
        $($dbsetLine)

        public $($SolutionName)DbContext(DbContextOptions<$($SolutionName)DbContext> options)
            : base(options) { }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            $($configLine)
            base.OnModelCreating(builder);
        }
    }
}

"@ | Set-Content -Path "Infrastructure\$($SolutionName).Persistence\$($SolutionName)DbContext.cs" 

@" 
namespace $($SolutionName).Persistence
{
    public class DbInitializer
    {
        public static void Initialize($($SolutionName)DbContext context)
        {
            context.Database.EnsureCreated();
        }
    }
}

"@ | Set-Content -Path "Infrastructure\$($SolutionName).Persistence\DbInitializer.cs" 
@" 
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using $($SolutionName).Application.Interfaces;

namespace $($SolutionName).Persistence
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddPersistence(this IServiceCollection
            services, IConfiguration configuration)
        {
            var connectionString = configuration["DbConnection"];
            services.AddDbContext<$($SolutionName)DbContext>(options =>
            {
                options.UseSqlite(connectionString);
            });
            services.AddScoped<I$($SolutionName)DbContext>(provider =>
                provider.GetService<$($SolutionName)DbContext>());
            return services;
        }
    }
}

"@ | Set-Content -Path "Infrastructure\$($SolutionName).Persistence\DependencyInjection.cs"
}

function Create-WebApi-Files{
    param (
        [string]$ModelName
    )
	@" 
{
  "DbConnection": "Data Source=$($VendorName).$($SolutionName).db",
  "AllowedHosts": "*"
}
"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\appsettings.json"


@" 
using System;
using System.Reflection;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace $($SolutionName).WebApi
{
    public class ConfigureSwaggerOptions : IConfigureOptions<SwaggerGenOptions>
    {
        private readonly IApiVersionDescriptionProvider _provider;

        public ConfigureSwaggerOptions(IApiVersionDescriptionProvider provider) =>
            _provider = provider;

        public void Configure(SwaggerGenOptions options)
        {
            foreach(var description in _provider.ApiVersionDescriptions)
            {
                var apiVersion = description.ApiVersion.ToString();
                options.SwaggerDoc(description.GroupName,
                    new OpenApiInfo
                    {
                        Version = apiVersion,
                        Title = $"$($SolutionName) API {apiVersion}",
                        Description =
                            "A simple example ASP NET Core Web API. Professional way",
                        TermsOfService =
                            new Uri("https://www.youtube.com/c/_TechTalks"),
                        Contact = new OpenApiContact
                        {
                            Name = "Chat",
                            Email = string.Empty,
                            Url =
                                new Uri("https://t.me/_chat")
                        },
                        License = new OpenApiLicense
                        {
                            Name = "Telegram Channel",
                            Url =
                                new Uri("https://t.me/_tech_talks")
                        }
                    });

                options.AddSecurityDefinition($"AuthToken {apiVersion}",
                    new OpenApiSecurityScheme
                    {
                        In = ParameterLocation.Header,
                        Type = SecuritySchemeType.Http,
                        BearerFormat = "JWT",
                        Scheme = "bearer",
                        Name = "Authorization",
                        Description = "Authorization token"
                    });

                options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = $"AuthToken {apiVersion}"
                            }
                        },
                        new string[] { }
                    }
                });

                options.CustomOperationIds(apiDescription =>
                    apiDescription.TryGetMethodInfo(out MethodInfo methodInfo)
                        ? methodInfo.Name
                        : null);
            }
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\ConfigureSwaggerOptions.cs"

@" 
using System;
using System.Security.Claims;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;

namespace $($SolutionName).WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]/[action]")]
    public abstract class BaseController : ControllerBase
    {
        private IMediator _mediator;
        protected IMediator Mediator =>
            _mediator ??= HttpContext.RequestServices.GetService<IMediator>();

        internal Guid UserId => !User.Identity.IsAuthenticated
            ? Guid.Empty
            : Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier).Value);
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Controllers\BaseController.cs"
@" 
using AutoMapper;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using $($SolutionName).Application.$($ModelName)s.Queries.Get$($ModelName)List;
using $($SolutionName).Application.$($ModelName)s.Queries.Get$($ModelName)Details;
using $($SolutionName).Application.$($ModelName)s.Commands.Create$($ModelName);
using $($SolutionName).Application.$($ModelName)s.Commands.Update$($ModelName);
using $($SolutionName).Application.$($ModelName)s.Commands.DeleteCommand;
using $($SolutionName).WebApi.Models;

namespace $($SolutionName).WebApi.Controllers
{
    [ApiVersion("1.0")]
    [ApiVersion("2.0")]
    [Produces("application/json")]
    [Route("api/{version:apiVersion}/[controller]")]
    public class $($ModelName)Controller : BaseController
    {
        private readonly IMapper _mapper;

        public $($ModelName)Controller(IMapper mapper) => _mapper = mapper;

        /// <summary>
        /// Gets the list of model
        /// </summary>
        /// <remarks>
        /// Sample request:
        /// GET /model
        /// </remarks>
        /// <returns>Returns $($ModelName)ListVm</returns>
        /// <response code="200">Success</response>
        /// <response code="401">If the user is unauthorized</response>
        [HttpGet]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<$($ModelName)ListVm>> GetAll()
        {
            var query = new Get$($ModelName)ListQuery
            {
                UserId = UserId
            };
            var vm = await Mediator.Send(query);
            return Ok(vm);
        }

        /// <summary>
        /// Gets the model by id
        /// </summary>
        /// <remarks>
        /// Sample request:
        /// GET /model/D34D349E-43B8-429E-BCA4-793C932FD580
        /// </remarks>
        /// <param name="id">$($ModelName) id (guid)</param>
        /// <returns>Returns $($ModelName)DetailsVm</returns>
        /// <response code="200">Success</response>
        /// <response code="401">If the user in unauthorized</response>
        [HttpGet("{id}")]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<$($ModelName)DetailsVm>> Get(Guid id)
        {
            var query = new Get$($ModelName)DetailsQuery
            {
                UserId = UserId,
                Id = id
            };
            var vm = await Mediator.Send(query);
            return Ok(vm);
        }

        /// <summary>
        /// Creates the model
        /// </summary>
        /// <remarks>
        /// Sample request:
        /// POST /model
        /// {
        ///     title: "model title",
        ///     details: "model details"
        /// }
        /// </remarks>
        /// <param name="create$($ModelName)Dto">Create$($ModelName)Dto object</param>
        /// <returns>Returns id (guid)</returns>
        /// <response code="201">Success</response>
        /// <response code="401">If the user is unauthorized</response>
        [HttpPost]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<Guid>> Create([FromBody] Create$($ModelName)Dto create$($ModelName)Dto)
        {
            var command = _mapper.Map<Create$($ModelName)Command>(create$($ModelName)Dto);
            command.UserId = UserId;
            var modelId = await Mediator.Send(command);
            return Ok(modelId);
        }

        /// <summary>
        /// Updates the model
        /// </summary>
        /// <remarks>
        /// Sample request:
        /// PUT /model
        /// {
        ///     title: "updated model title"
        /// }
        /// </remarks>
        /// <param name="update$($ModelName)Dto">Update$($ModelName)Dto object</param>
        /// <returns>Returns NoContent</returns>
        /// <response code="204">Success</response>
        /// <response code="401">If the user is unauthorized</response>
        [HttpPut]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Update([FromBody] Update$($ModelName)Dto update$($ModelName)Dto)
        {
            var command = _mapper.Map<Update$($ModelName)Command>(update$($ModelName)Dto);
            command.UserId = UserId;
            await Mediator.Send(command);
            return NoContent();
        }

        /// <summary>
        /// Deletes the model by id
        /// </summary>
        /// <remarks>
        /// Sample request:
        /// DELETE /model/88DEB432-062F-43DE-8DCD-8B6EF79073D3
        /// </remarks>
        /// <param name="id">Id of the model (guid)</param>
        /// <returns>Returns NoContent</returns>
        /// <response code="204">Success</response>
        /// <response code="401">If the user is unauthorized</response>
        [HttpDelete("{id}")]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Delete(Guid id)
        {
            var command = new Delete$($ModelName)Command
            {
                Id = id,
                UserId = UserId
            };
            await Mediator.Send(command);
            return NoContent();
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Controllers\$($ModelName)Controller.cs"
@" 
using System;
using System.Threading.Tasks;
using System.Net;
using System.Text.Json;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using $($SolutionName).Application.Common.Exceptions;

namespace $($SolutionName).WebApi.Middleware
{
    public class CustomExceptionHandlerMiddleware
    {
        private readonly RequestDelegate _next;

        public CustomExceptionHandlerMiddleware(RequestDelegate next) =>
            _next = next;

        public async Task Invoke(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch(Exception exception)
            {
                await HandleExceptionAsync(context, exception);
            }
        }

        private Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            var code = HttpStatusCode.InternalServerError;
            var result = string.Empty;
            switch(exception)
            {
                case ValidationException validationException:
                    code = HttpStatusCode.BadRequest;
                    result = JsonSerializer.Serialize(validationException.Errors);
                    break;
                case NotFoundException:
                    code = HttpStatusCode.NotFound;
                    break;
            }
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)code;

            if (result == string.Empty)
            {
                result = JsonSerializer.Serialize(new { error = exception.Message });
            }

            return context.Response.WriteAsync(result);
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Middleware\CustomExceptionHandlerMiddleware.cs"
@" 
using Microsoft.AspNetCore.Builder;

namespace $($SolutionName).WebApi.Middleware
{
    public static class CustomExceptionHandlerMiddlewareExtensions
    {
        public static IApplicationBuilder UseCustomExceptionHandler(this
            IApplicationBuilder builder)
        {
            return builder.UseMiddleware<CustomExceptionHandlerMiddleware>();
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Middleware\CustomExceptionHandlerMiddlewareExtensions.cs"
@" 
using AutoMapper;
using $($SolutionName).Application.Common.Mappings;
using $($SolutionName).Application.$($ModelName)s.Commands.Create$($ModelName);
using System.ComponentModel.DataAnnotations;

namespace $($SolutionName).WebApi.Models
{
    public class Create$($ModelName)Dto : IMapWith<Create$($ModelName)Command>
    {
        [Required]
        public string Title { get; set; } // TODO: Переписать
        //public string Details { get; set; }  

        public void Mapping(Profile profile)
        {
            profile.CreateMap<Create$($ModelName)Dto, Create$($ModelName)Command>()
                .ForMember(modelCommand => modelCommand.Title,
                    opt => opt.MapFrom(modelDto => modelDto.Title));
               /* .ForMember(modelCommand => modelCommand.Details,
                    opt => opt.MapFrom(modelDto => modelDto.Details))*/
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Models\Create$($ModelName)Dto.cs"
@"
using AutoMapper;
using System;
using $($SolutionName).Application.Common.Mappings;
using $($SolutionName).Application.$($ModelName)s.Commands.Update$($ModelName);

namespace $($SolutionName).WebApi.Models
{
    public class Update$($ModelName)Dto : IMapWith<Update$($ModelName)Command>
    {
		//TODO: Переписать
        public Guid Id { get; set; }
        public string Title { get; set; }
       // public string Details { get; set; }

        public void Mapping(Profile profile)
        {
            profile.CreateMap<Update$($ModelName)Dto, Update$($ModelName)Command>()
                .ForMember(modelCommand => modelCommand.Id,
                    opt => opt.MapFrom(modelDto => modelDto.Id))
                .ForMember(modelCommand => modelCommand.Title,
                    opt => opt.MapFrom(modelDto => modelDto.Title));
               /* .ForMember(modelCommand => modelCommand.Details,
                    opt => opt.MapFrom(modelDto => modelDto.Details))*/
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Models\Update$($ModelName)Dto.cs"
@" 
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using Serilog.Events;
using System;
using $($SolutionName).Persistence;

namespace $($SolutionName).WebApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
                .WriteTo.File("$($SolutionName)WebAppLog-.txt", rollingInterval:
                    RollingInterval.Day)
                .CreateLogger();

            var host = CreateHostBuilder(args).Build();

            using (var scope = host.Services.CreateScope())
            {
                var serviceProvider = scope.ServiceProvider;
                try
                {
                    var context = serviceProvider.GetRequiredService<$($SolutionName)DbContext>();
                    DbInitializer.Initialize(context);
                }
                catch (Exception exception)
                {
                    Log.Fatal(exception, "An error occurred while app initialization");
                }
            }

            host.Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Program.cs"
@" 
using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using $($SolutionName).Application.Interfaces;

namespace $($SolutionName).WebApi.Services
{
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor) =>
            _httpContextAccessor = httpContextAccessor;

        public Guid UserId
        {
            get
            {
                var id = _httpContextAccessor.HttpContext?.User?
                    .FindFirstValue(ClaimTypes.NameIdentifier);
                return string.IsNullOrEmpty(id) ? Guid.Empty : Guid.Parse(id);
            }
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Services\CurrentUserService.cs"
@" 

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using System.Reflection;
using Swashbuckle.AspNetCore.SwaggerGen;
using $($SolutionName).Application;
using $($SolutionName).Application.Common.Mappings;
using $($SolutionName).Application.Interfaces;
using $($SolutionName).Persistence;
using $($SolutionName).WebApi.Middleware;
using $($SolutionName).WebApi.Services;

namespace $($SolutionName).WebApi
{
    public class Startup
    {
        public IConfiguration Configuration { get; }

        public Startup(IConfiguration configuration) => Configuration = configuration;

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddAutoMapper(config =>
            {
                config.AddProfile(new AssemblyMappingProfile(Assembly.GetExecutingAssembly()));
                config.AddProfile(new AssemblyMappingProfile(typeof(I$($SolutionName)DbContext).Assembly));
            });

            services.AddApplication();
            services.AddPersistence(Configuration);
            services.AddControllers();

            services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyHeader();
                    policy.AllowAnyMethod();
                    policy.AllowAnyOrigin();
                });
            });

            services.AddAuthentication(config =>
            {
                config.DefaultAuthenticateScheme =
                    JwtBearerDefaults.AuthenticationScheme;
                config.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
                .AddJwtBearer("Bearer", options =>
                {
                    options.Authority = "https://localhost:44386/";
                    options.Audience = "$($SolutionName)WebAPI";
                    options.RequireHttpsMetadata = false;
                });

            services.AddVersionedApiExplorer(options =>
                options.GroupNameFormat = "'v'VVV");
            services.AddTransient<IConfigureOptions<SwaggerGenOptions>,
                    ConfigureSwaggerOptions>();
            services.AddSwaggerGen();
            services.AddApiVersioning();

            services.AddSingleton<ICurrentUserService, CurrentUserService>();
            services.AddHttpContextAccessor();
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env,
            IApiVersionDescriptionProvider provider)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            app.UseSwagger();
            app.UseSwaggerUI(config =>
            {
                foreach (var description in provider.ApiVersionDescriptions)
                {
                    config.SwaggerEndpoint(
                        $"/swagger/{description.GroupName}/swagger.json",
                        description.GroupName.ToUpperInvariant());
                    config.RoutePrefix = string.Empty;
                }
            });
            app.UseCustomExceptionHandler();
            app.UseRouting();
            app.UseHttpsRedirection();
            app.UseCors("AllowAll");
            app.UseAuthentication();
            app.UseAuthorization();
            app.UseApiVersioning();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).WebApi\Startup.cs"
}
