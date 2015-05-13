using afMorphia

const mixin EntityDao {

	abstract Datastore 		datastore()
	abstract IntSequences	intSeqs()
	
	virtual Obj create(Obj entity) {
		idField := entity.typeof.field("_id", false) 
		if (idField != null) {
			id := idField.get(entity)
			if (id == null || id == 0) {
				id = intSeqs.nextId(entity.typeof)
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

	virtual Void dropAll() {
		datastore.drop(false)
	}

	protected virtual QueryCriterion field(Str fieldName) {
		Query().field(fieldName)
	}
}
