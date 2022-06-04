using afIoc::Inject
using afMorphia::Datastore
using afMorphia::Entity
using afMongo::MongoSeqs

abstract const class EntityDao {

			abstract		Datastore	datastore()
	@Inject private	const	MongoSeqs	intSeqs
	
	new make(|This| fn) { fn(this) }
	
	virtual Obj create(Obj entity) {
		idField := entity.typeof.field("_id", false) 
		if (idField != null) {
			id := idField.get(entity)
			if (id == null || id == 0) {
				ent := entity.typeof.facet(Entity#) as Entity
				id = intSeqs.nextId(ent?.name ?: entity.typeof.name)
				idField.set(entity, id)
			}
		}
		return datastore.insert(entity)
	}

	virtual Obj update(Obj entity) {
		datastore.update(entity)
		return entity
	}

	virtual Void delete(Obj entity) {
		datastore.delete(entity)
	}

	virtual Void deleteById(Obj id, Bool checked := true) {
		datastore.deleteById(id, checked)
	}

	virtual Void dropAll() {
		datastore.drop(false)
	}
}
